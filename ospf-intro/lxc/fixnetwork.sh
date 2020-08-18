#!/bin/sh

sed -i '/lxc.net/d' R*/config H*/config

cat <<EOF >> R1/config
lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = vlan1001
lxc.net.0.veth.pair = r1.1001
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch
lxc.net.0.hwaddr = 02:00:0a:00:01:05
lxc.net.0.ipv4.address = 10.0.1.5/24
lxc.net.1.type = veth
lxc.net.1.flags = up
lxc.net.1.name = vlan1012
lxc.net.1.veth.pair = r1.1012
lxc.net.1.script.up = /etc/lxc/lxc-openvswitch
lxc.net.1.script.down = /etc/lxc/lxc-openvswitch
lxc.net.1.hwaddr = 02:00:0a:01:02:07
lxc.net.1.ipv4.address = 10.1.2.7/24
lxc.net.2.type = veth
lxc.net.2.flags = up
lxc.net.2.name = vlan1356
lxc.net.2.veth.pair = r1.1356
lxc.net.2.script.up = /etc/lxc/lxc-openvswitch
lxc.net.2.script.down = /etc/lxc/lxc-openvswitch
lxc.net.2.hwaddr = 02:00:0a:03:38:01
lxc.net.2.ipv4.address = 10.3.56.1/24
EOF

cat <<EOF >> R2/config
lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = vlan1012
lxc.net.0.veth.pair = r2.1012
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch
lxc.net.0.hwaddr = 02:00:0a:01:02:7b
lxc.net.0.ipv4.address = 10.1.2.123/24
lxc.net.1.type = veth
lxc.net.1.flags = up
lxc.net.1.name = vlan1082
lxc.net.1.veth.pair = r2.1082
lxc.net.1.script.up = /etc/lxc/lxc-openvswitch
lxc.net.1.script.down = /etc/lxc/lxc-openvswitch
lxc.net.1.hwaddr = 02:00:0a:08:02:01
lxc.net.1.ipv4.address = 10.8.2.1/24
lxc.net.2.type = veth
lxc.net.2.flags = up
lxc.net.2.name = vlan1050
lxc.net.2.veth.pair = r2.1050
lxc.net.2.script.up = /etc/lxc/lxc-openvswitch
lxc.net.2.script.down = /etc/lxc/lxc-openvswitch
lxc.net.2.hwaddr = 02:00:0a:32:01:01
lxc.net.2.ipv4.address = 10.50.1.1/24
EOF

cat <<EOF >> R5/config
lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = vlan1001
lxc.net.0.veth.pair = r5.1001
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch
lxc.net.0.hwaddr = 02:00:0a:00:01:04
lxc.net.0.ipv4.address = 10.0.1.4/24
lxc.net.1.type = veth
lxc.net.1.flags = up
lxc.net.1.name = vlan1012
lxc.net.1.veth.pair = r5.1012
lxc.net.1.script.up = /etc/lxc/lxc-openvswitch
lxc.net.1.script.down = /etc/lxc/lxc-openvswitch
lxc.net.1.hwaddr = 02:00:0a:01:02:38
lxc.net.1.ipv4.address = 10.1.2.56/24
EOF

cat <<EOF >> R6/config
lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = vlan1001
lxc.net.0.veth.pair = r6.1001
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch
lxc.net.0.hwaddr = 02:00:0a:00:01:08
lxc.net.0.ipv4.address = 10.0.1.8/24
lxc.net.1.type = veth
lxc.net.1.flags = up
lxc.net.1.name = vlan1034
lxc.net.1.veth.pair = r6.1034
lxc.net.1.script.up = /etc/lxc/lxc-openvswitch
lxc.net.1.script.down = /etc/lxc/lxc-openvswitch
lxc.net.1.hwaddr = 02:00:0a:2b:02:01
lxc.net.1.ipv4.address = 10.34.2.1/24
EOF

cat <<EOF >> H12/config
lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = vlan1050
lxc.net.0.veth.pair = h12.1050
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch
lxc.net.0.hwaddr = 02:00:0a:32:01:0c
lxc.net.0.ipv4.address = 10.50.1.12/24
lxc.net.0.ipv4.gateway = 10.50.1.1
EOF

cat <<EOF >> H10/config
lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = vlan1082
lxc.net.0.veth.pair = h10.1082
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch
lxc.net.0.hwaddr = 02:00:0a:08:02:0a
lxc.net.0.ipv4.address = 10.8.2.10/24
lxc.net.0.ipv4.gateway = 10.8.2.1
EOF

cat <<EOF >> H8/config
lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = vlan1356
lxc.net.0.veth.pair = h8.1356
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch
lxc.net.0.hwaddr = 02:00:0a:03:38:08
lxc.net.0.ipv4.address = 10.3.56.8/24
lxc.net.0.ipv4.gateway = 10.3.56.1
EOF

cat <<EOF >> H5/config
lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.name = vlan1034
lxc.net.0.veth.pair = h5.1034
lxc.net.0.script.up = /etc/lxc/lxc-openvswitch
lxc.net.0.script.down = /etc/lxc/lxc-openvswitch
lxc.net.0.hwaddr = 02:00:0a:2b:02:05
lxc.net.0.ipv4.address = 10.34.2.5/24
lxc.net.0.ipv4.gateway = 10.34.2.1
EOF
