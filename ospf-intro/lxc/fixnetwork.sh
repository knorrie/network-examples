#!/bin/sh

cat <<EOF >> R1/config
lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan1001
lxc.network.veth.pair = r1.1001
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:00:01:05
lxc.network.ipv4 = 10.0.1.5/24
lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan1012
lxc.network.veth.pair = r1.1012
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:01:02:07
lxc.network.ipv4 = 10.1.2.7/24
lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan1356
lxc.network.veth.pair = r1.1356
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:03:38:01
lxc.network.ipv4 = 10.3.56.1/24
EOF

cat <<EOF >> R2/config
lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan1012
lxc.network.veth.pair = r2.1012
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:01:02:7b
lxc.network.ipv4 = 10.1.2.123/24
lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan1082
lxc.network.veth.pair = r2.1082
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:08:02:01
lxc.network.ipv4 = 10.8.2.1/24
lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan1050
lxc.network.veth.pair = r2.1050
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:32:01:01
lxc.network.ipv4 = 10.50.1.1/24
EOF

cat <<EOF >> R5/config
lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan1001
lxc.network.veth.pair = r5.1001
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:00:01:04
lxc.network.ipv4 = 10.0.1.4/24
lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan1012
lxc.network.veth.pair = r5.1012
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:01:02:38
lxc.network.ipv4 = 10.1.2.56/24
EOF

cat <<EOF >> R6/config
lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan1001
lxc.network.veth.pair = r6.1001
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:00:01:08
lxc.network.ipv4 = 10.0.1.8/24
lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan1034
lxc.network.veth.pair = r6.1034
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:2b:02:01
lxc.network.ipv4 = 10.34.2.1/24
EOF

cat <<EOF >> H12/config
lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan1050
lxc.network.veth.pair = h12.1050
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:32:01:0c
lxc.network.ipv4 = 10.50.1.12/24
lxc.network.ipv4.gateway = 10.50.1.1
EOF

cat <<EOF >> H10/config
lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan1082
lxc.network.veth.pair = h10.1082
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:08:02:0a
lxc.network.ipv4 = 10.8.2.10/24
lxc.network.ipv4.gateway = 10.8.2.1
EOF

cat <<EOF >> H8/config
lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan1356
lxc.network.veth.pair = h8.1356
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:03:38:08
lxc.network.ipv4 = 10.3.56.8/24
lxc.network.ipv4.gateway = 10.3.56.1
EOF

cat <<EOF >> H5/config
lxc.network.type = veth
lxc.network.flags = up
lxc.network.name = vlan1034
lxc.network.veth.pair = h5.1034
lxc.network.script.up = /etc/lxc/lxc-openvswitch
lxc.network.hwaddr = 02:00:0a:2b:02:05
lxc.network.ipv4 = 10.34.2.5/24
lxc.network.ipv4.gateway = 10.34.2.1
EOF
