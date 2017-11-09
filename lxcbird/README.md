# Setting up a lab environment

For the tutorials, I've chosen to use Debian GNU/Linux with lxc, btrfs and openvswitch and some extra git thrown at it to build simulations of complete networks. The current stable Debian Release, 9 (Stretch) already contains everything you need for this.

So, make sure you get your hands on an empty physical or virtual machine. The one I use is a standard Debian x86-64 (a.k.a. amd64) virtual machine.

 * LXC provides a very lightweight way to run containers with their own network namespace, separated from each other.
 * I use btrfs subvolumes as container filesystems.
 * The advantage of using openvswitch is that we can very easily run a vlan capable switch, by just configuring ports on it as either access or trunk port with any of the vlan numbers assigned, much like you would do with a physical switch.
 * Creating a git repository just outside the container root filesystems with a .gitignore that only includes specific files allows to easily store the configuration of a whole test network. For example, when destroying a complete container and cloning it from another container again, a simple git checkout is enough to put the configuration inside the container back in place.

Here's a simple schematic overview of what I mean:

![lxc-openvswitch-topology](/lxcbird/lxc-openvswitch-topology.png)

## Some basic packages

To be able to create containers and hook up their network interfaces to openvswitch, we need the following packages:

    apt-get install lxc debootstrap openvswitch-switch git

## Setting up networking

The lxc host system only needs a single external network interface, for you to manage it, and probably to masquerade outgoing traffic from the test environment, using NAT. It's of course also possible to route some real address space to this box for use in the test networks, but I'm not doing so.

Here's the `/etc/network/interfaces` of my lxc host, well, almost, since I replaced the eth0 addresses with fakes:

    lxcbird:/etc/network 0-# cat interfaces
    auto lo
    iface lo inet loopback

    auto eth0
    iface eth0 inet manual
        up ip link set up dev eth0
        up ip addr add 10.255.1.34/24 brd + dev eth0
        up ip addr add 2001:db8:ffff::22/64 dev eth0
        up ip route add default via 10.255.1.1 dev eth0
        up ip route add default via 2001:db8:ffff::1 dev eth0
        down ip -6 route del default
        down ip addr del 2001:db8:ffff::22/64 dev eth0
        down ip addr del 10.255.1.34/24 dev eth0
        down ip link set down dev eth0

    allow-ovs ovs0
    iface ovs0 inet manual
        pre-up ovs-vsctl add-br ovs0
        up ip link set up dev ovs0
        down ip link set down dev ovs0
        post-down ovs-vsctl del-br ovs0

    allow-ovs vlan10
    iface vlan10 inet manual
        pre-up ovs-vsctl add-port ovs0 vlan10 tag=10 -- set interface vlan10 type=internal
        up ip link set up dev vlan10
        up ip addr add 198.51.100.1/24 brd + dev vlan10
        up ip addr add 2001:db8:1998::1/120 dev vlan10
        down ip addr del 2001:db8:1998::1/120 dev vlan10
        down ip addr del 198.51.100.1/24 dev vlan10
        down ip link set down dev vlan10
        post-down ovs-vsctl del-port ovs0 vlan10

As you can see, I'm not a fan of the default way `network/interfaces` works in Debian. Actually, I always use manual mode and (pre-)up and (post-)down rules to set up and tear down everything. This is more convenient if you don't like magic too much, and often work with multiple addresses and extra commands on interfaces.

## Masquerading outgoing traffic

To enable masquerading outgoing traffic from the test networks, make sure you enable IP forwarding, for example by putting the following settings in the `/etc/sysctl.conf`...

    net.ipv4.ip_forward = 1
    net.ipv6.conf.all.forwarding = 1
    net.ipv6.conf.default.forwarding = 1

...and by using a few simple netfilter rules to do the NAT, like...

    *nat
    -A POSTROUTING -o eth0 -j MASQUERADE
    COMMIT
    *filter
    :FORWARD DROP [0:0]
    -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    -A FORWARD -i vlan10 -o eth0 -j ACCEPT
    COMMIT

...which can be done for IPv4, as well as for IPv6, because NAT for IPv6 has finally been implemented. For test environments like this, it's very helpful, since we can just use documentation addresses from `2001:db8::/32` and are still able to access the outside internet if needed.

## Setting up version control

    lxcbird:/var/lib/lxc 0-# git init
    Initialized empty Git repository in /var/lib/lxc-bird/.git/

Now make sure your `.gitignore` looks like this, to include only very specific files from all containers:

    lxcbird:/var/lib/lxc 0-# cat .gitignore
    *.log
    */*
    !*/config
    !*/rootfs
    */rootfs/*
    !*/rootfs/etc/
    */rootfs/etc/*
    !*/rootfs/etc/hosts
    !*/rootfs/etc/sysctl.conf

    !*/rootfs/etc/network/
    */rootfs/etc/network/*
    !*/rootfs/etc/network/interfaces
    !*/rootfs/etc/network/firewall
    !*/rootfs/etc/network/firewall6

    !*/rootfs/etc/bird/
    */rootfs/etc/bird/*
    !*/rootfs/etc/bird/bird.conf
    !*/rootfs/etc/bird/bird6.conf
    lxcbird:/var/lib/lxc 0-# git add .gitignore
    lxcbird:/var/lib/lxc 0-# git commit -m "Only include specific files from containers"
    [master (root-commit) 8ecfeec] Only include specific files from containers
     1 file changed, 20 insertions(+)
     create mode 100644 .gitignore

## Creating the first container

Here's an example to create a first container, which we'll configure a bit and use as a template to clone all other containers from.

    lxcbird:/var/lib/lxc 0-# MIRROR=http://ftp.nl.debian.org/debian lxc-create -t debian -B btrfs -n birdbase -- -r stretch

### Configure the network and openvswitch up/down script

In `birdbase/config`, lxc-create has put some basic configuration. The networking configuration has to be set up now, so we can test our connectivity and install some extra software. To be able to do so, I'm going to configure it with an IPv4 and IPv6 address in the range of vlan10, and point my default gateway to the lxc host system.

In the config file, instead of...

    lxc.network.type = empty

...it should look more like this...

    lxc.network.type = veth
    lxc.network.name = vlan10
    lxc.network.veth.pair = birdbase.10
    lxc.network.flags = up
    lxc.network.script.up = /etc/lxc/lxc-openvswitch
    lxc.network.script.down = /etc/lxc/lxc-openvswitch

...oh, and by the way, the lxc network script referenced is a really simple script to integrate lxc with openvswitch, which simply attaches an interface in the container to a vlan inside openvswitch based on the number after the dot. It has to be present on the host system, not in the container:

    lxcbird:/etc/lxc 0-# cat lxc-openvswitch
    #!/bin/sh

    # $1 container name
    # $2 config section name (net)
    # $3 execution context (up/down)
    # $4 network type (empty/veth/macvlan/phys)
    # $5 (host-sided) device name

    if [ "$3" = "up" ]
    then
        vlan=$(echo "$5" | awk -F . '{ print $NF }')
        ovs-vsctl add-port ovs0 $5 tag=$vlan
    else
        ovs-vsctl del-port ovs0 $5
    fi

Instead of setting the container IP address and gateway in the lxc configuration file, I prefer using network/interfaces inside the container, because we'll be using that for more complex networking anyway in the tutorials:

    lxcbird:/var/lib/lxc/birdbase 0-# cat rootfs/etc/network/interfaces
    auto lo
    iface lo inet loopback

    auto vlan10
    iface vlan10 inet manual
        up ip link set up dev vlan10
        up ip addr add 198.51.100.254/24 brd + dev vlan10
        up ip addr add 2001:db8:1998::fe/120 dev vlan10
        up ip route add default via 198.51.100.1 dev vlan10
        up ip route add default via 2001:db8:1998::1 dev vlan10
        down ip -6 route del default
        down ip addr del 2001:db8:1998::fe/120 dev vlan10
        down ip route del default
        down ip addr del 198.51.100.254/24 dev vlan10
        down ip link set down dev vlan10

### Prevent Debian from installing unnecessary packages

Now, before starting it, we need to finish up a few basic configuration settings...

    lxcbird:/var/lib/lxc/birdbase 0-# echo 'APT::Install-Recommends "false";' > rootfs/etc/apt/apt.conf.d/00InstallRecommends

I hate the default of installing recommends in Debian, so I always turn that off. Generally, it's recommended to install Recommends when using Debian, so it installs other packages that are 'generally found together with these ones'. Generally, I don't really see the pattern in this, and I recommend to just try disabling Recommends to see which issues you run into, so you learn more about how related software works together. Anyway, for your minimal BIRD lxc container, we won't run into any problem doing so now.

### Start!

Now, let's try to start it and see what happens!

    lxcbird:/var/lib/lxc/birdbase 0-# lxc-start -d -n birdbase
    lxcbird:/var/lib/lxc/birdbase 0-# lxc-attach -n birdbase
    root@birdbase:/# 
    root@birdbase:/# ip a
    1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default 
        link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
        inet 127.0.0.1/8 scope host lo
           valid_lft forever preferred_lft forever
        inet6 ::1/128 scope host 
           valid_lft forever preferred_lft forever
    215: vlan10: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
        link/ether 02:00:c6:33:64:fe brd ff:ff:ff:ff:ff:ff
        inet 198.51.100.254/24 brd 198.51.100.255 scope global vlan10
           valid_lft forever preferred_lft forever
        inet6 2001:db8:1998::fe/120 scope global 
           valid_lft forever preferred_lft forever
        inet6 fe80::c6ff:fe33:64fe/64 scope link 
           valid_lft forever preferred_lft forever

Let's verify if we have proper outgoing network connectivity!

    root@birdbase:/# ping knorrie.org
    bash: ping: command not found

Oh, there's our first problem... it's still a bit too basic :)

## Finishing our birdbase container

    root@birdbase:/# apt-get update
    [...]
    root@birdbase:/# apt-get install iputils-ping bird dnsutils iptables iptstate mtr-tiny tcpdump nmon traceroute iftop iperf3
    [...]

The fact that we can do this already proves networking is set up right!

    root@birdbase:/# ping -n -c 3 knorrie.org
    PING knorrie.org (82.94.188.77) 56(84) bytes of data.
    64 bytes from 82.94.188.77: icmp_seq=1 ttl=54 time=6.64 ms
    64 bytes from 82.94.188.77: icmp_seq=2 ttl=54 time=5.12 ms
    64 bytes from 82.94.188.77: icmp_seq=3 ttl=54 time=3.91 ms

    --- knorrie.org ping statistics ---
    3 packets transmitted, 3 received, 0% packet loss, time 2002ms
    rtt min/avg/max/mdev = 3.913/5.228/6.646/1.118 ms
    root@birdbase:/# ping6 -n -c 3 knorrie.org
    PING knorrie.org(2001:888:2177::4d) 56 data bytes
    64 bytes from 2001:888:2177::4d: icmp_seq=1 ttl=53 time=5.51 ms
    64 bytes from 2001:888:2177::4d: icmp_seq=2 ttl=53 time=3.99 ms
    64 bytes from 2001:888:2177::4d: icmp_seq=3 ttl=53 time=3.39 ms

    --- knorrie.org ping statistics ---
    3 packets transmitted, 3 received, 0% packet loss, time 2002ms
    rtt min/avg/max/mdev = 3.398/4.302/5.513/0.890 ms

And now ping confirms it. Both IPv4 and IPv6 masquerading works.

### BIRD auto start

Now, enable starting bird, since for some reason this is not automatically done when installing it:

    root@birdbase:/# systemctl enable bird
    Synchronizing state for bird.service with sysvinit using update-rc.d...
    Executing /usr/sbin/update-rc.d bird defaults
    Executing /usr/sbin/update-rc.d bird enable
    root@birdbase:/# systemctl enable bird6
    Synchronizing state for bird6.service with sysvinit using update-rc.d...
    Executing /usr/sbin/update-rc.d bird6 defaults
    Executing /usr/sbin/update-rc.d bird6 enable

### BIRD logfile location

Since there is no separate syslog process in the container, create a directory where we can point logging configuration to later:

    root@birdbase:/# mkdir /var/log/bird
    root@birdbase:/# chown bird: /var/log/bird
    root@birdbase:/# true > /var/log/bird/bird.log; chown bird: /var/log/bird/bird.log
    root@birdbase:/# true > /var/log/bird/bird6.log; chown bird: /var/log/bird/bird6.log

The creation of the log file is necessary to work around a bug in the Debian packaging, that causes the logfile to be created with root as owner, and subsequent causes bird startup to fail because it cannot write to the logfile as user bird. :-(

### IP forwarding

For IP forwarding, make sure you uncomment `net.ipv4.ip_forward=1` and `net.ipv6.conf.all.forwarding=1` in sysctl.conf inside the container. Hint: editing configuration files inside a container can be done from outside the container, by looking for them in the `rootfs` folder inside the container directories.

## Disabling icmp error rate limiting

Since we'll be doing a lot of tracerouting in the example networks, it's nice to disable icmp error rate limiting in sysctl.conf, to prevent hickups while executing quick subsequent traceroute commands:

    net.ipv4.icmp_ratelimit = 0
    net.ipv6.icmp.ratelimit = 0

You probably wouldn't want to do this in a production network. For more information, see [the blog post "A strange packet loss"](http://backreference.org/2012/11/16/a-strange-packet-loss/)

### Root password

You might also want to change the password for root, since it's set to some random string by default.

## Cleanup

Before the birdbase container is ready as a template to be used for cloning other containers, let's shut it down and remove some container-specific configuration, so we won't accidentally start a new one with duplicate configuration, and, to make the diff look nicer when configuring a clone:

    lxcbird:/var/lib/lxc 1-# lxc-stop -n birdbase

    lxcbird:/var/lib/lxc 1-# sed -i /^lxc.network/d birdbase/config
    lxcbird:/var/lib/lxc 1-# /bin/true > birdbase/rootfs/etc/bird/bird.conf
    lxcbird:/var/lib/lxc 1-# /bin/true > birdbase/rootfs/etc/bird/bird6.conf
    lxcbird:/var/lib/lxc 1-# /bin/true > birdbase/rootfs/etc/network/interfaces

Finally, we can check that git only wants to store our bird and network configuration, and do so:

    lxcbird:/var/lib/lxc/birdbase 0-# git status
    On branch master
    Untracked files:
      (use "git add <file>..." to include in what will be committed)

        ./

    nothing added to commit but untracked files present (use "git add" to track)
    lxcbird:/var/lib/lxc/birdbase 0-# git add .
    lxcbird:/var/lib/lxc/birdbase 0-# git status
    On branch master
    Changes to be committed:
      (use "git reset HEAD <file>..." to unstage)

        new file:   config
        new file:   rootfs/etc/sysctl.conf
        new file:   rootfs/etc/bird/bird.conf
        new file:   rootfs/etc/bird/bird6.conf
        new file:   rootfs/etc/network/interfaces

    lxcbird:/var/lib/lxc/birdbase 0-# git commit -m "birdbase network and bird config"
    [...]

Right! As you might notice, there are "end-hosts" in the drawing on top of this page, and we just configured the base container to start bird and enable IP forwarding. While this is not needed, or wanted for the end host containers, I don't really care, because it will not influence the working of the test environment, as bird has no configuration, end hosts will not attract traffic that's not for themselves. However, if you like, you can create two different containers to clone from, one for a router, and one for an end host.

Let's head over to the next page to [meet the Birdhouse Factory network](/birdhouse-intro/README.md)!
