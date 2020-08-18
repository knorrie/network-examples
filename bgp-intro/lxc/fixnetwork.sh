#!/bin/sh

sed -i '/lxc.net/d' R*/config H*/config

cat <<EOF >> H6/config

lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = vlan2
lxc.net.0.veth.pair = h6.2
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch
lxc.net.0.hwaddr = 02:00:0a:28:02:06
EOF

cat <<EOF >> R0/config

lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = vlan216
lxc.net.0.veth.pair = r0.216
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch
lxc.net.0.hwaddr = 02:00:0a:28:d8:02

lxc.net.1.type = veth
lxc.net.1.flags = up
lxc.net.1.name = vlan2
lxc.net.1.veth.pair = r0.2
lxc.net.1.script.up = /etc/lxc/lxc-openvswitch
lxc.net.1.script.down = /etc/lxc/lxc-openvswitch
lxc.net.1.hwaddr = 02:00:0a:28:02:01
EOF

cat <<EOF >> H7/config

lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = vlan3
lxc.net.0.veth.pair = h7.3
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch
lxc.net.0.hwaddr = 02:00:0a:28:03:07
EOF

cat <<EOF >> R1/config

lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = vlan216
lxc.net.0.veth.pair = r1.216
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch
lxc.net.0.hwaddr = 02:00:0a:28:d8:03

lxc.net.1.type = veth
lxc.net.1.flags = up
lxc.net.1.name = vlan3
lxc.net.1.veth.pair = r1.3
lxc.net.1.script.up = /etc/lxc/lxc-openvswitch
lxc.net.1.script.down = /etc/lxc/lxc-openvswitch
lxc.net.1.hwaddr = 02:00:0a:28:03:01
EOF

cat <<EOF >> R3/config

lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = vlan216
lxc.net.0.veth.pair = r3.216
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch
lxc.net.0.hwaddr = 02:00:0a:28:d8:01

lxc.net.1.type = veth
lxc.net.1.flags = up
lxc.net.1.name = vlan217
lxc.net.1.veth.pair = r3.217
lxc.net.1.script.up = /etc/lxc/lxc-openvswitch
lxc.net.1.script.down = /etc/lxc/lxc-openvswitch
lxc.net.1.hwaddr = 02:00:0a:28:d9:10
EOF

cat <<EOF >> R10/config

lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = vlan33
lxc.net.0.veth.pair = r10.33
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch
lxc.net.0.hwaddr = 02:00:0a:28:21:01

lxc.net.1.type = veth
lxc.net.1.flags = up
lxc.net.1.name = vlan217
lxc.net.1.veth.pair = r10.217
lxc.net.1.script.up = /etc/lxc/lxc-openvswitch
lxc.net.1.script.down = /etc/lxc/lxc-openvswitch
lxc.net.1.hwaddr = 02:00:0a:28:d9:11
EOF

cat <<EOF >> R11/config

lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = vlan33
lxc.net.0.veth.pair = r11.33
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch
lxc.net.0.hwaddr = 02:00:0a:28:21:02

lxc.net.1.type = veth
lxc.net.1.flags = up
lxc.net.1.name = vlan48
lxc.net.1.veth.pair = r11.48
lxc.net.1.script.up = /etc/lxc/lxc-openvswitch
lxc.net.1.script.down = /etc/lxc/lxc-openvswitch
lxc.net.1.hwaddr = 02:00:0a:28:30:01
EOF

cat <<EOF >> H19/config

lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = vlan48
lxc.net.0.veth.pair = h19.48
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch
lxc.net.0.hwaddr = 02:00:0a:28:34:13
EOF

cat <<EOF >> R12/config

lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = vlan33
lxc.net.0.veth.pair = r12.33
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch
lxc.net.0.hwaddr = 02:00:0a:28:21:03

lxc.net.1.type = veth
lxc.net.1.flags = up
lxc.net.1.name = vlan36
lxc.net.1.veth.pair = r12.36
lxc.net.1.script.up = /etc/lxc/lxc-openvswitch
lxc.net.1.script.down = /etc/lxc/lxc-openvswitch
lxc.net.1.hwaddr = 02:00:0a:28:24:01
EOF

cat <<EOF >> H34/config

lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = vlan36
lxc.net.0.veth.pair = h34.36
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch
lxc.net.0.hwaddr = 02:00:0a:28:24:22
EOF
