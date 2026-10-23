#!/usr/bin/env python3
# nettest.py IMAGE OUT CYB... - CyborgOS-Next's network in ZEsarUX: espsim.py (a stand-in ESP on a
# pseudo-terminal, real sockets behind it) bridged to the emulated Next's UART, echo.php served on
# this machine (port 8083), the .CYB files given put in C:CYBORGOS/, NextZXOS booted into CyborgOS,
# then NET ESP, IPCONFIG, NETSTAT and HTTPTEST http://127.0.0.1:8083/echo.php typed; a picture of the
# screen (OUT-1.png, OUT-2.png) after each pair, espsim's log in OUT.esp.log.
# Needs ZEsarUX built with --uartbridge-path (ZES: its folder's parent - the scratch harness), its
# remote protocol on port 10000, pyfatfs, php.
# (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
import sys, os, time, shutil, subprocess, socket
S = os.environ.get('ZES', '/tmp/claude-0/-home-claude/6ab1b76e-9415-53d5-9ffa-4d518563895a/scratchpad')
HERE = os.path.dirname(os.path.abspath(__file__))
COS = os.path.abspath(os.path.join(HERE, '..', '..'))
img, out = sys.argv[1:3]
shutil.copy(img, S + '/net.mmc')
from pyfatfs import PyFatFS
fs = PyFatFS.PyFatFS(S + '/net.mmc', offset=2048 * 512)
for src in sys.argv[3:]:
    dst = '/CYBORGOS/' + os.path.basename(src).upper()
    if fs.exists(dst):
        fs.remove(dst)
    fs.writebytes(dst, open(src, 'rb').read())
fs.close()

env = dict(os.environ, ESPSIM_LOG='1')
esp = subprocess.Popen(['python3', HERE + '/espsim.py', S + '/esp.path'], stdout=subprocess.PIPE,
                       stderr=open(out + '.esp.log', 'w'), env=env)
pty = esp.stdout.readline().decode().strip()
web = S + '/netweb'
os.makedirs(web, exist_ok=True)
shutil.copy(COS + '/src/bas/cyborgos320kb/cmds/test/echo.php', web + '/echo.php')
php = subprocess.Popen(['php', '-S', '127.0.0.1:8083'], cwd=web, stdout=subprocess.DEVNULL, stderr=open(out + '.php.log', 'w'))
subprocess.run(['pkill', '-x', 'zesarux']); time.sleep(1)
zes = subprocess.Popen(['./zesarux', '--noconfigfile', '--machine', 'tbblue', '--vo', 'null', '--ao', 'null',
    '--nowelcomemessage', '--enable-remoteprotocol', '--remoteprotocol-port', '10000', '--verbose', '1',
    '--realvideo', '--enable-mmc', '--enable-divmmc-ports', '--enable-divmmc-paging', '--mmc-file', S + '/net.mmc',
    '--mmc-no-persistent-writes', '--uartbridge-path', pty], cwd=S + '/zesarux/src',
    stdout=open(out + '.zes.log', 'w'), stderr=subprocess.STDOUT)
time.sleep(4)
sys.path.insert(0, S)
from zrcp import Z
z = Z()
def key(k, t=0.15):
    z.cmd('send-keys-event %d 1' % k); time.sleep(t); z.cmd('send-keys-event %d 0' % k)
def typ(c, w=6):
    z.cmd('send-keys-string 150 ' + c); time.sleep(0.25 * len(c) + 0.5)
    z.cmd('send-keys-ascii 150 13'); time.sleep(w)
def shot(n):
    f = os.path.abspath('%s-%d.bmp' % (out, n))
    z.cmd('save-screen ' + f); time.sleep(1)
    try:
        from PIL import Image
        Image.open(f).save(f[:-4] + '.png')
    except Exception as e:
        print('shot %d: %s' % (n, e))
time.sleep(30); key(129); time.sleep(12); key(32); time.sleep(25)
typ('net esp', 10)
typ('ipconfig', 8)
shot(1)
typ('netstat', 6)
typ('httptest http://127.0.0.1:8083/echo.php', 40)
shot(2)
typ('net get 127.0.0.1:8083/echo.php?q=hello', 20)
shot(3)
for p in (zes, php, esp):
    p.terminate()
