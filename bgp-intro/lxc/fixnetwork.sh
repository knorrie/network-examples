#!/bin/sh

sed -i '/lxc.network/d' R*/config H*/config

cat <<EOF >> H6/config

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan2
lxc.network.veth.pair = h6.2
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:28:02:06
EOF

cat <<EOF >> R0/config

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan216
lxc.network.veth.pair = r0.216
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:28:d8:02

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan2
lxc.network.veth.pair = r0.2
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:28:02:01
EOF

cat <<EOF >> H7/config

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan3
lxc.network.veth.pair = h7.3
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:28:03:07
EOF

cat <<EOF >> R1/config

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan216
lxc.network.veth.pair = r1.216
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:28:d8:03

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan3
lxc.network.veth.pair = r1.3
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:28:03:01
EOF

cat <<EOF >> R3/config

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan216
lxc.network.veth.pair = r3.216
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:28:d8:01

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan217
lxc.network.veth.pair = r3.217
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:28:d9:10
EOF

cat <<EOF >> R10/config

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan33
lxc.network.veth.pair = r10.33
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:28:21:01

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan217
lxc.network.veth.pair = r10.217
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:28:d9:11
EOF

cat <<EOF >> R11/config

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan33
lxc.network.veth.pair = r11.33
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:28:21:02

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan48
lxc.network.veth.pair = r11.48
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:28:30:01
EOF

cat <<EOF >> H19/config

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan48
lxc.network.veth.pair = h19.48
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:28:34:13
EOF

cat <<EOF >> R12/config

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan33
lxc.network.veth.pair = r12.33
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:28:21:03

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan36
lxc.network.veth.pair = r12.36
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:28:24:01
EOF

cat <<EOF >> H34/config

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan36
lxc.network.veth.pair = h34.36
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:28:24:22
EOF
