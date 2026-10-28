# zxntest.py IMAGE GUI.CYB GUIDEMO.CYB OUT [steps...]: GUI on CyborgOS-Next in ZEsarUX - the card image
# with the two programs put in C:CYBORGOS/ (GUI in C:CYBORGOS/C/), NextZXOS booted, RUN 2 GUI KEYS, RUN 3 GUIDEMO, Caps
# Shift + 2, then each step (a key: tab, space, enter, or text to type; "shot" a picture
# OUT-n.png of GUI's screen; "wait"), the pictures by zxnshot.py.
# Needs ZEsarUX (the scratch harness's runzes2.sh) and its remote protocol on port 10000.
# (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
import sys, os, time, shutil, subprocess
S = os.environ.get('ZES', '/tmp/claude-0/-home-claude/6ab1b76e-9415-53d5-9ffa-4d518563895a/scratchpad')
HERE = os.path.dirname(os.path.abspath(__file__))
img, gui, demo, out = sys.argv[1:5]
shutil.copy(img, S + '/cos.mmc')
from pyfatfs import PyFatFS
fs = PyFatFS.PyFatFS(S + '/cos.mmc', offset=2048 * 512)
for src, dst in ((gui, '/CYBORGOS/C/GUI.CYB'), (demo, '/CYBORGOS/GUIDEMO.CYB')):   # (the Next's GUI in C/: the CPC's is CYBORGOS/GUI.CYB)
    b = open(src, 'rb').read()
    if fs.exists(dst):
        if fs.readbytes(dst) == b: continue      # (the card has it already: dist.sh puts them there)
        fs.remove(dst)
    fs.writebytes(dst, b)
fs.close()
subprocess.run(['bash', S + '/runzes2.sh'])
sys.path.insert(0, S)
from zrcp import Z
z = Z()
def key(k, t=0.15):
    z.cmd('send-keys-event %d 1' % k); time.sleep(t); z.cmd('send-keys-event %d 0' % k)
def typ(c):
    z.cmd('send-keys-string 150 ' + c); time.sleep(0.25 * len(c) + 0.5)
time.sleep(30); key(129); time.sleep(12); key(32); time.sleep(25)
typ('run 2 gui keys'); z.cmd('send-keys-ascii 150 13'); time.sleep(10)
typ('run 3 guidemo'); z.cmd('send-keys-ascii 150 13'); time.sleep(10)
z.cmd('send-keys-event 135 1'); time.sleep(0.3); z.cmd('send-keys-event 50 1'); time.sleep(0.6)
z.cmd('send-keys-event 50 0'); time.sleep(0.2); z.cmd('send-keys-event 135 0'); time.sleep(8)
n = 0
for st in sys.argv[5:]:
    if st == 'shot':
        n += 1; z.s.close()
        subprocess.run(['python3', HERE + '/zxnshot.py', '%s-%d.png' % (out, n)])
        z = Z()
    elif st == 'wait': time.sleep(5)
    elif st == 'tab':                     # Break (Caps Shift + Space): GUI's next control
        z.cmd('send-keys-event 135 1'); time.sleep(0.2); z.cmd('send-keys-event 32 1'); time.sleep(0.3)
        z.cmd('send-keys-event 32 0'); time.sleep(0.1); z.cmd('send-keys-event 135 0'); time.sleep(2)
    elif st == 'space': z.cmd('send-keys-ascii 150 32'); time.sleep(3)
    elif st == 'enter': z.cmd('send-keys-ascii 150 13'); time.sleep(3)
    else: typ(st); time.sleep(2)
