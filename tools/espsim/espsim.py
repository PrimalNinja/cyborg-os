#!/usr/bin/env python3
# espsim.py - a stand-in for the ZX Spectrum Next's ESP8266 wifi (its AT firmware), for testing
# CyborgOS's ESP driver in an emulator: it makes a pseudo-terminal, prints its path (ZEsarUX:
# --uartbridge-path that path) and answers the AT commands the driver uses - with real sockets
# on this machine, so a test's web server (php -S) answers the Next's GETs.
#   python3 espsim.py [pathfile]      (the pty's path also written to pathfile, if given)
# Answers as ESP8266 AT firmware 1.7 does (passive receive mode: +IPD,n,len notices, the data
# fetched with AT+CIPRECVDATA). The network it says it is on: TestNet, 192.168.1.77.
# ESPSIM_LOG=1: each command and answer to stderr.
# (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
import os, sys, tty, socket, select, time, re

LOG = bool(os.environ.get('ESPSIM_LOG'))
g_intMaster, g_intSlave = os.openpty()
tty.setraw(g_intSlave)
g_strPath = os.ttyname(g_intSlave)
print(g_strPath, flush=True)
if len(sys.argv) > 1:
    open(sys.argv[1], 'w').write(g_strPath)

g_objSocks = {}          # link -> socket
g_objNotified = {}       # link -> bytes already announced with +IPD
g_blnEcho = True
g_blnPassive = False
g_bytIn = b''

def out(bytData_a):
    if LOG:
        print('<< %r' % bytData_a, file=sys.stderr)
    os.write(g_intMaster, bytData_a)

def line(strText_a):
    out(strText_a.encode('latin-1') + b'\r\n')

def ok():
    out(b'\r\nOK\r\n')

def err():
    out(b'\r\nERROR\r\n')

def readn(intN_a):
    # the next n bytes from the Next (a CIPSEND's data), waited for
    global g_bytIn
    while len(g_bytIn) < intN_a:
        r, _, _ = select.select([g_intMaster], [], [], 5)
        if not r:
            break
        g_bytIn += os.read(g_intMaster, 4096)
    d = g_bytIn[:intN_a]
    g_bytIn = g_bytIn[intN_a:]
    return d

def command(strCmd_a):
    global g_blnEcho, g_blnPassive
    if LOG:
        print('>> %r' % strCmd_a, file=sys.stderr)
    if g_blnEcho:
        out(strCmd_a.encode('latin-1') + b'\r\n')
    c = strCmd_a.strip()
    m = None
    if c == 'AT':
        ok()
    elif c == 'ATE0':
        g_blnEcho = False
        ok()
    elif c == 'AT+CIPMUX=1':
        ok()
    elif c == 'AT+CIPRECVMODE=1':
        g_blnPassive = True
        ok()
    elif c.startswith('AT+CIPCLOSE='):
        n = int(c[12:])
        if n == 5:
            for k in list(g_objSocks):
                g_objSocks.pop(k).close()
            ok()
        elif n in g_objSocks:
            g_objSocks.pop(n).close()
            g_objNotified.pop(n, None)
            line('%d,CLOSED' % n)
            ok()
        else:
            err()
    elif c.startswith('AT+CIPDOMAIN='):
        name = c[13:].strip('"')
        try:
            ip = socket.gethostbyname(name)
            line('+CIPDOMAIN:' + ip)
            ok()
        except OSError:
            line('DNS Fail')
            err()
    elif c.startswith('AT+CIPSTART='):
        m = re.match(r'AT\+CIPSTART=(\d),"TCP","([^"]+)",(\d+)', c)
        if not m:
            err()
        else:
            n = int(m.group(1))
            s = socket.socket()
            s.settimeout(5)
            try:
                s.connect((m.group(2), int(m.group(3))))
                s.setblocking(False)
                g_objSocks[n] = s
                g_objNotified[n] = 0
                line('%d,CONNECT' % n)
                ok()
            except OSError:
                err()
    elif c.startswith('AT+CIPSEND='):
        m = re.match(r'AT\+CIPSEND=(\d),(\d+)', c)
        n = int(m.group(1)) if m else -1
        if n not in g_objSocks:
            err()
        else:
            ln = int(m.group(2))
            ok()
            out(b'> ')
            d = readn(ln)
            try:
                g_objSocks[n].setblocking(True)
                g_objSocks[n].sendall(d)
                g_objSocks[n].setblocking(False)
                line('')
                line('Recv %d bytes' % len(d))
                line('')
                line('SEND OK')
            except OSError:
                line('SEND FAIL')
    elif c.startswith('AT+CIPRECVDATA='):
        m = re.match(r'AT\+CIPRECVDATA=(\d),(\d+)', c)
        n = int(m.group(1)) if m else -1
        if n not in g_objSocks:
            err()
        else:
            try:
                d = g_objSocks[n].recv(int(m.group(2)))
            except BlockingIOError:
                d = b''
            except OSError:
                d = b''
            g_objNotified[n] = max(0, g_objNotified.get(n, 0) - len(d))
            out(('+CIPRECVDATA,%d:' % len(d)).encode() + d)
            ok()
    elif c == 'AT+CWJAP_CUR?' or c == 'AT+CWJAP?':
        line('+CWJAP_CUR:"TestNet","aa:bb:cc:dd:ee:ff",6,-58')
        ok()
    elif c == 'AT+CIPSTA_CUR?' or c == 'AT+CIPSTA?':
        line('+CIPSTA_CUR:ip:"192.168.1.77"')
        line('+CIPSTA_CUR:gateway:"192.168.1.1"')
        line('+CIPSTA_CUR:netmask:"255.255.255.0"')
        ok()
    elif c == 'AT+CIPSTAMAC_CUR?' or c == 'AT+CIPSTAMAC?':
        line('+CIPSTAMAC_CUR:"5c:cf:7f:aa:bb:cc"')
        ok()
    elif c.startswith('AT+CWJAP_DEF=') or c.startswith('AT+CWJAP='):
        print('ESPSIM joins %s' % c.split('=', 1)[1], file=sys.stderr)
        line('WIFI DISCONNECT')
        line('WIFI CONNECTED')
        line('WIFI GOT IP')
        ok()
    else:
        err()

def notices():
    # passive mode: data waiting announced (+IPD,n,len - the new bytes), a closed socket (n,CLOSED)
    for n, s in list(g_objSocks.items()):
        try:
            d = s.recv(65536, socket.MSG_PEEK)
            if len(d) == 0:
                g_objSocks.pop(n).close()
                g_objNotified.pop(n, None)
                line('%d,CLOSED' % n)
            elif len(d) > g_objNotified.get(n, 0):
                line('+IPD,%d,%d' % (n, len(d) - g_objNotified.get(n, 0)))
                g_objNotified[n] = len(d)
        except BlockingIOError:
            pass
        except OSError:
            g_objSocks.pop(n, None)
            line('%d,CLOSED' % n)

line('ready')
while True:
    r, _, _ = select.select([g_intMaster], [], [], 0.05)
    if r:
        try:
            g_bytIn += os.read(g_intMaster, 4096)
        except OSError:
            time.sleep(0.05)
    while b'\r\n' in g_bytIn:
        bytLine, g_bytIn = g_bytIn.split(b'\r\n', 1)
        if bytLine:
            command(bytLine.decode('latin-1'))
    if g_blnPassive:
        notices()
