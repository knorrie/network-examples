# A basic network example

In the very first part of this tutorial, we're going to play around with the linux containers and networking a bit, and introduce the network of a fictional company that I'll be using as example in the tutorials.

The goal is to become comfortable with quickly setting up and tearing down example networks.

## The Birdhouse Factory

Well, there it is... The Birdhouse Factory network:

![Birdhouse Network](/birdhouse-intro/birdhouse-intro.png)

The Birdhouse Factory is a fictional company that manufactures little wooden birdhouses. Besides their manufactoring process and the warehouse, they have an office where accounting and sales people work.

Since the Birdhouse Factory people also like internet technology, they combined these interests and run their own webshop where you can buy birdhouses online, and their own mail server. The Factory has some IPv4 space allocated from an ISP, where they run their servers, and where they have a NAT router in front of their office network, which uses RFC1918 IPv4 network ranges.

## Cloning and configuring new containers

After following the [tutorial to set up a lab environment](/lxcbird/README.md) we end up with the first container, "birdbase". Make sure this birdbase container is stopped (by using `lxc-stop`, or typing `halt` on the container prompt after using `lxc-attach`), so it can be cloned into new ones.

    lxcbird:/var/lib/lxc 0-# lxc-ls --fancy
    NAME      STATE    IPV4  IPV6  AUTOSTART
    ----------------------------------------
    .git      STOPPED  -     -     NO
    birdbase  STOPPED  -     -     NO

Heh, `lxc-ls` is not that clever, and also thinks my git repository is a container. Oh well...

Let's create some of the systems shown in the network picture:

    lxcbird:/var/lib/lxc 0-# lxc-clone -s birdbase sparrow
    Created container sparrow as snapshot of birdbase
    lxcbird:/var/lib/lxc 0-# lxc-clone -s birdbase weaver
    Created container weaver as snapshot of birdbase

Now we need to configure the network interfaces and add a little iptables ruleset for the NAT gateway.

### Sparrow

Sparrow has two interfaces, one in vlan10, the network to run public services, and vlan60, the office network. In `sparrow/config`, network interfaces are defined:

    lxc.network.type = veth
    lxc.network.name = vlan10
    lxc.network.veth.pair = sparrow.10
    lxc.network.script.up = /etc/lxc/lxc-openvswitch
    lxc.network.script.down = /etc/lxc/lxc-openvswitch
    lxc.network.hwaddr = 02:00:c6:33:64:13
    lxc.network.type = veth
    lxc.network.name = vlan60
    lxc.network.veth.pair = sparrow.60
    lxc.network.script.up = /etc/lxc/lxc-openvswitch
    lxc.network.script.down = /etc/lxc/lxc-openvswitch
    lxc.network.hwaddr = 02:00:0a:01:3c:01

And they're configured with addresses in `sparrow/rootfs/etc/network/interfaces`:

    auto lo
    iface lo inet loopback

    auto vlan10
    iface vlan10 inet manual
        pre-up iptables-restore < /etc/network/firewall
        up ip link set up dev vlan10
        up ip addr add 198.51.100.19/26 brd + dev vlan10
        up ip route add default via 198.51.100.1 dev vlan10
        down ip addr del 198.51.100.19/26 dev vlan10
        down ip link set down dev vlan10

    auto vlan60
    iface vlan60 inet manual
        up ip link set up dev vlan60
        up ip addr add 10.1.60.1/24 brd + dev vlan60
        down ip addr del 10.1.60.1/24 dev vlan60
        down ip link set down dev vlan60

In order to activate NAT, here's the bare minimal thing to put in `sparrow/rootfs/etc/network/firewall`:

    *nat
    -A POSTROUTING -o vlan10 -j MASQUERADE
    COMMIT

Now, start the container with `lxc-start -d -n sparrow` and get a command prompt with `lxc-attach -n sparrow`. Use `ip a`, `ip r` etc, to verify that addresses and routes are set correctly.

### Weaver

Weaver is a bit simpler, since it's just an end host with one network interface. For `weaver/config`:

    lxc.network.type = veth
    lxc.network.name = vlan60
    lxc.network.veth.pair = weaver.60
    lxc.network.script.up = /etc/lxc/lxc-openvswitch
    lxc.network.script.down = /etc/lxc/lxc-openvswitch
    lxc.network.hwaddr = 02:00:0a:01:3c:15

And `weaver/rootfs/etc/network/interfaces`:

    auto lo
    iface lo inet loopback

    auto vlan60
    iface vlan60 inet manual
        up ip link set up dev vlan60
        up ip addr add 10.1.60.21/24 brd + dev vlan60
        up ip route add default via 10.1.60.1 dev vlan60
        down ip addr del 10.1.60.21/24 dev vlan60
        down ip link set down dev vlan60

Start weaver, get a command prompt, and see if you have proper connectivity to the outside internet. Traceroute something outside for example. If not, debug the IP addresses and routes and fix it.

## Finishing up... some assignments.

The "ISP Router" functionality can be handled by the LXC host machine, as shown in the [introduction](/lxcbird/README.md).

To finish this tutorial:
 * Verify how openvswitch is used by looking at the output of `ovs-vsctl show` in the lxc host machine.
 * Create a third container, the webshop server, and configure it. Confirm you can reach it from weaver, by running a SimpleHTTPServer with python (`python -m SimpleHTTPServer`) and pointing wget to it from weaver. You should see the outside IPv4 address of sparrow as source address of the request because of the NAT. Also, because of the NAT, the webshop server does not need to know a route to the `10.1.60.0/24` network, because it's hidden behind sparrow.

That's basically it. As you can see, when you get the hang of this, it's instantly also getting extremely boring to do the configuration every time. For later tutorials, I'll make sure all files that make up the starting point of the configuration are available to simply copy into the newly cloned containers.
