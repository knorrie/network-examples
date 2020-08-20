#!/bin/sh

sed -i '/lxc.network/d' R*/config

cat <<EOF >> R0/config

lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = lan
lxc.net.0.veth.pair = r0.1
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch

lxc.net.1.type = veth
lxc.net.1.flags = up
lxc.net.1.name = ebgp_r11
lxc.net.1.veth.pair = r0.3
lxc.net.1.script.up = /etc/lxc/lxc-openvswitch
lxc.net.1.script.down = /etc/lxc/lxc-openvswitch
EOF

cat <<EOF >> R1/config

lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = lan
lxc.net.0.veth.pair = r1.1
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch

lxc.net.1.type = veth
lxc.net.1.flags = up
lxc.net.1.name = ebgp_r10
lxc.net.1.veth.pair = r1.4
lxc.net.1.script.up = /etc/lxc/lxc-openvswitch
lxc.net.1.script.down = /etc/lxc/lxc-openvswitch

lxc.net.2.type = veth
lxc.net.2.flags = up
lxc.net.2.name = ebgp_r20
lxc.net.2.veth.pair = r1.5
lxc.net.2.script.up = /etc/lxc/lxc-openvswitch
lxc.net.2.script.down = /etc/lxc/lxc-openvswitch
EOF

cat <<EOF >> R2/config

lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = lan
lxc.net.0.veth.pair = r2.1
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch
EOF

cat <<EOF >> R10/config

lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = lan
lxc.net.0.veth.pair = r10.2
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch

lxc.net.1.type = veth
lxc.net.1.flags = up
lxc.net.1.name = ebgp_r1
lxc.net.1.veth.pair = r10.4
lxc.net.1.script.up = /etc/lxc/lxc-openvswitch
lxc.net.1.script.down = /etc/lxc/lxc-openvswitch
EOF

cat <<EOF >> R11/config

lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = lan
lxc.net.0.veth.pair = r11.2
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch

lxc.net.1.type = veth
lxc.net.1.flags = up
lxc.net.1.name = ebgp_r0
lxc.net.1.veth.pair = r11.3
lxc.net.1.script.up = /etc/lxc/lxc-openvswitch
lxc.net.1.script.down = /etc/lxc/lxc-openvswitch

lxc.net.2.type = veth
lxc.net.2.flags = up
lxc.net.2.name = ebgp_r20
lxc.net.2.veth.pair = r11.6
lxc.net.2.script.up = /etc/lxc/lxc-openvswitch
lxc.net.2.script.down = /etc/lxc/lxc-openvswitch
EOF

cat <<EOF >> R12/config

lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = lan
lxc.net.0.veth.pair = r12.2
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch
EOF

cat <<EOF >> R20/config

lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = ebgp_r1
lxc.net.0.veth.pair = r20.5
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch

lxc.net.1.type = veth
lxc.net.1.flags = up
lxc.net.1.name = ebgp_r11
lxc.net.1.veth.pair = r20.6
lxc.net.1.script.up = /etc/lxc/lxc-openvswitch
lxc.net.1.script.down = /etc/lxc/lxc-openvswitch
EOF

