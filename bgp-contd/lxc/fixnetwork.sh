#!/bin/sh

sed -i '/lxc.network/d' R*/config

cat <<EOF >> R0/config

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = ibgp
lxc.network.veth.pair = r0.1
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = ebgp_r10
lxc.network.veth.pair = r0.3
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch
EOF

cat <<EOF >> R1/config

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = ibgp
lxc.network.veth.pair = r1.1
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = ebgp_r11
lxc.network.veth.pair = r1.4
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = ebgp_r20
lxc.network.veth.pair = r1.5
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch
EOF

cat <<EOF >> R2/config

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = ibgp
lxc.network.veth.pair = r2.1
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch
EOF

cat <<EOF >> R10/config

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = ibgp
lxc.network.veth.pair = r10.2
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = ebgp_r0
lxc.network.veth.pair = r10.3
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = ebgp_r20
lxc.network.veth.pair = r10.6
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch
EOF

cat <<EOF >> R11/config

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = ibgp
lxc.network.veth.pair = r11.2
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = ebgp_r1
lxc.network.veth.pair = r11.4
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch
EOF

cat <<EOF >> R12/config

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = ibgp
lxc.network.veth.pair = r12.2
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch
EOF

cat <<EOF >> R20/config

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = ebgp_r1
lxc.network.veth.pair = r20.5
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch

lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = ebgp_r10
lxc.network.veth.pair = r20.6
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.script.down = /etc/lxc/lxc-openvswitch
EOF

