# cosd - CyborgOS's Pi side

The services a CPC (or a ZX Spectrum Next) asks for over its link to a Raspberry Pi: STORE (tagged
data kept on the Pi), DISK (Pi volumes as drives, with random access), RUN (a command, its output back), TERM (the CPC as the Pi's terminal), MATH
(a coprocessor), VDU (a full HD virtual display on the Pi's HDMI), AUDIO. The protocol:
[docs/cyborgos-pi.md](../docs/cyborgos-pi.md).

| File | What |
|---|---|
| `cosd.js` | the daemon: the link, the channels, the control channel |
| `proto.js` | the frames (shared with cosctl.js) |
| `svc/*.js` | the services |
| `web/vdu.html` | the virtual display's page (it uses `../tools/vdu/vdu.js`) |
| `cplink-bridge.c` | the CPC-CPLink / CPLink2 card's GPIO to a TCP socket (C: Node is too slow a byte) |
| `cosctl.js` | a stand-in for the CPC: the protocol from any computer; a module for the tests |
| `test/run.js` | the tests: `node pi/test/run.js` (56) |

## On the Pi (Raspberry Pi OS)

```
sudo apt install nodejs mpg123 alsa-utils          # Node 14 or later; the players for AUDIO
cd cyborgos/pi
cc -O2 -o cplink-bridge cplink-bridge.c            # the CPLink's GPIO (no library needed)
./cplink-bridge 7001 &                              # the FIFO on 127.0.0.1:7001, the Pi ROM on 7002
node cosd.js --link=cplink:7001                     # a CPC-CPLink
node cosd.js --link=cplink2:7001                    # a CPLink2: big answers through its Pi ROM
node cosd.js --link=serial:/dev/ttyAMA0:115200      # a serial line (the Next's Pi Zero, USIfAC)
```

The user needs the gpio group for /dev/gpiomem (the default pi user has it). Two cards on one CPC
(two Pis): each Pi runs its own bridge and cosd. The virtual display: a browser full screen on
the HDMI, e.g. `chromium-browser --kiosk http://localhost:8084/` (started at login); any browser
on the LAN can watch the same page.

To start them at boot, two systemd units (as the pi user):

```
# /etc/systemd/system/cplink-bridge.service      # /etc/systemd/system/cosd.service
[Service]                                        [Service]
ExecStart=/home/pi/cyborgos/pi/cplink-bridge 7001 ExecStart=/usr/bin/node /home/pi/cyborgos/pi/cosd.js --link=cplink2:7001
User=pi                                          User=pi
Restart=always                                   Restart=always
[Install]                                        [Install]
WantedBy=multi-user.target                       WantedBy=multi-user.target
```

`--no-run` keeps RUN and TERM off (no shell from the link). STORE keeps its tags in
`~/.cosd/store/<machine>/` (`--store=DIR`). The Pi volumes (DISK) are `/home/cyborgos/<volume>/`,
their mounts in `/home/cyborgos/volumes.json` (`--volumes=DIR`): run cosd as a user `cyborgos`
(`sudo adduser cyborgos; sudo adduser cyborgos gpio`), or give /home/cyborgos to the user it runs as.

## From a PC (no CPC needed)

```
node pi/cosd.js --link=tcp:7000 &
node pi/cosctl.js time
node pi/cosctl.js run "ls -l"
node pi/cosctl.js store put hello.txt README.md
node pi/cosctl.js math "sqrt(2) * 10"
node pi/cosctl.js vol new games; node pi/cosctl.js vol mount GAMES G; node pi/cosctl.js vol find G:*.*
node pi/cosctl.js term                     # a shell on the Pi in this terminal: Ctrl+] ends it
node pi/cosctl.js vdu hd < picture.txt     # then http://localhost:8084/
```

(c) 2026 Cyborg Unicorn Pty Ltd - MIT License
