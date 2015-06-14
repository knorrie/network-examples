BGP, Part I
===========

In the previous tutorial, we discovered how to let [OSPF](/ospf-intro/README.md) dynamically configure routing inside a network. This tutorial provides an introduction to another routing protocol, which is BGP, the Border Gateway Protocol. As the name implies, this protocol acts on the border of a network. Where OSPF is well suited to keep track of all tiny details of what's happening in our internal network, BGP will be talking to the outside world to interconnect our network with other networks, managed by someone else.

## BGP Essentials

When routers talk BGP to each other, they essentially just claim that network ranges are reachable via them:

![BGP network, barebones](/bgp-intro/bgp-heythere.png)

Let's look at the same picture again, hiding less information:

![BGP network, less simplified](/bgp-intro/bgp-hey2.png)

The picture shows two networks, which are interconnected through router `R3` and `R10`.

 * A complete network under control of somebody has an AS ([Autonomous System](https://tools.ietf.org/html/rfc1930)) number. By specifying the AS number when configuring BGP connections, we let it know if the neighbour is in our own network (our AS), or in an external network (another AS).
 * If neighbouring routers between different networks are directly connected, they often interconnect using a minimal sized network range. For IPv4, this is usually a `/30` and for IPv6 a `/120` or a `/126` prefix, containing only the two routers. In the example above, the small network ranges are taken from the network of `AS64080`.
 * The routes that are published to another network are as aggregated as possible, to minimize the amount of them. While the internal routing table in for example `AS64080` might contain dozens of prefixes, for each little vlan, and probably a number of single host routes (IPv4 `/32` and IPv6 `/128`), they're advertised to the outside as just three routes in total.

## OSPF vs. BGP

While the title of this section might seem logical, since we're considering BGP after just having spent quite some time on OSPF, it's actually a non-issue. OSPF and BGP are two very different routing protocols, which are used to get different things done. Nonetheless, let's look at some differences:

OSPF:
 * Routes in the network are originated by just putting ip addresses on a network interface of a router, and letting the routing protocol pick them up automatically.
 * The routes in OSPF are addresses and subnets that are actually in use.
 * Every router that participates in the OSPF protocol has a full detailed view on the network using link state updates that are broadcasted over the network.

BGP:
 * Routes that are published to other networks are "umbrella ranges", which are as big as possible and are defined manually.
 * There is no actual proof that the addresses which are advertised are actually in use inside the network.
 * A neighbour BGP router knows that some prefix is reachable via another network, but where OSPF shortest path deals with knowledge about all separate routers, paths and weights, BGP just looks on a higher level, the shortest path, considering a complete network (AS) being one step.

So, OSPF is an IGP (Interior Gateway Protocol) and BGP is an EGP (Exterior Gateway Protocol). BGP can connect OSPF networks to each other, hiding a lot of detail inside them.

## BGP and OSPF with BIRD

In the second half of this tutorial we'll configure a network, using OSPF, BGP and the BIRD routing software. BGP wise, it's kept simple, using just a single connection between two networks.

![BGP and OSPF network](/bgp-intro/bgp-ospf.png)

### Setting up the containers and networks

It's starting to look serious now! Thankfully, most of the configuration is provided already, so we can quickly set up this whole network using our LXC environment. Just like in the previous tutorial, the birdbase container can be cloned, after which the lxc network information and configuration inside the containers can be copied into them.

 1. Clone this git repository somewhere to be able to use some files from the bgp-intro/lxc/ directory inside.
 2. lxc-clone the birdbase container several times:

    lxc-clone -s birdbase R0
    lxc-clone -s birdbase R1
    lxc-clone -s birdbase R3
    lxc-clone -s birdbase R10
    lxc-clone -s birdbase R11
    lxc-clone -s birdbase R12
    lxc-clone -s birdbase H6
    lxc-clone -s birdbase H7
    lxc-clone -s birdbase H19
    lxc-clone -s birdbase H34

 3. Set up the network interfaces in the lxc configuration. This can be done by removing all network related configuration that remains from the cloned birdbase container, and then appending all needed interface configuration by running the fixnetwork.sh script that can be found in `ospf-intro/lxc/` in this git repository. Of course, have a look at the contents of the script first, before executing it. Since this example is only using IPv4 and single IP addresses on the interfaces, I simply added them to the lxc configuration instead of the network/interfaces file inside the container.

    . ./fixnetwork.sh

 4. Copy extra configuration into the containers. The bgp-intro/lxc/ directory inside this git repository contains a little file hierarchy that can just be copied over the configuration of the containers. For each router, it's a network/interfaces configuration file which adds an IP address that corresponds with the Router ID to the loopback interface, and a simple BIRD configuration file that serves as a starting point for our next steps.

 5. Start all containers

    lxc-start -d -n R0
    lxc-start -d -n R1
    lxc-start -d -n R3
    lxc-start -d -n R10
    lxc-start -d -n R11
    lxc-start -d -n R12
    lxc-start -d -n H6
    lxc-start -d -n H7
    lxc-start -d -n H19
    lxc-start -d -n H34

 6. Verify connectivity and look around a bit. Here's an example for R1:

    lxc-attach -n R1
    
    root@R1:/# ip a
    1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default 
        link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
        inet 127.0.0.1/8 scope host lo
           valid_lft forever preferred_lft forever
        inet 10.40.217.1/32 scope global lo
           valid_lft forever preferred_lft forever
        inet6 2001:db8:40::1/128 scope global 
           valid_lft forever preferred_lft forever
        inet6 ::1/128 scope host 
           valid_lft forever preferred_lft forever
    109: vlan216: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
        link/ether 02:00:0a:28:d8:03 brd ff:ff:ff:ff:ff:ff
        inet 10.40.216.3/28 brd 10.40.216.15 scope global vlan216
           valid_lft forever preferred_lft forever
        inet6 2001:db8:40:d8::3/120 scope global 
           valid_lft forever preferred_lft forever
        inet6 fe80::aff:fe28:d803/64 scope link 
           valid_lft forever preferred_lft forever
    111: vlan3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
        link/ether 02:00:0a:28:03:01 brd ff:ff:ff:ff:ff:ff
        inet 10.40.3.1/24 brd 10.40.3.255 scope global vlan3
           valid_lft forever preferred_lft forever
        inet6 2001:db8:40:3::1/120 scope global 
           valid_lft forever preferred_lft forever
        inet6 fe80::aff:fe28:301/64 scope link 
           valid_lft forever preferred_lft forever
    
    root@R1:/# ip r
    10.40.2.0/24 via 10.40.216.2 dev vlan216  proto bird 
    10.40.3.0/24 dev vlan3  proto kernel  scope link  src 10.40.3.1 
    10.40.216.0/28 dev vlan216  proto kernel  scope link  src 10.40.216.3 
    10.40.217.0 via 10.40.216.2 dev vlan216  proto bird 
    10.40.217.3 via 10.40.216.1 dev vlan216  proto bird 
    10.40.217.16/30 via 10.40.216.1 dev vlan216  proto bird 
    
    root@R1:/# birdc show route
    BIRD 1.4.5 ready.
    10.40.217.16/30    via 10.40.216.1 on vlan216 [ospf1 22:58:02] * I (150/20) [10.40.217.3]
    10.40.216.0/28     dev vlan216 [ospf1 22:58:02] * I (150/10) [10.40.217.3]
    10.40.217.0/32     via 10.40.216.2 on vlan216 [ospf1 22:58:02] * I (150/10) [10.40.217.0]
    10.40.217.1/32     dev lo [ospf1 22:57:42] * I (150/0) [10.40.217.1]
    10.40.217.3/32     via 10.40.216.1 on vlan216 [ospf1 22:58:02] * I (150/10) [10.40.217.3]
    10.40.2.0/24       via 10.40.216.2 on vlan216 [ospf1 22:58:02] * I (150/20) [10.40.217.0]
    10.40.3.0/24       dev vlan3 [ospf1 22:57:42] * I (150/10) [10.40.217.1]
    
    root@R1:/# ip -6 r
    2001:db8:40:: via fe80::aff:fe28:d802 dev vlan216  proto bird  metric 1024 
    unreachable 2001:db8:40::1 dev lo  proto kernel  metric 256  error -101
    2001:db8:40::3 via fe80::aff:fe28:d801 dev vlan216  proto bird  metric 1024 
    2001:db8:40:2::/120 via fe80::aff:fe28:d802 dev vlan216  proto bird  metric 1024 
    2001:db8:40:3::/120 dev vlan3  proto kernel  metric 256 
    2001:db8:40:d8::/120 dev vlan216  proto kernel  metric 256 
    2001:db8:40:d910::/120 via fe80::aff:fe28:d801 dev vlan216  proto bird  metric 1024 
    fe80::/64 dev vlan216  proto kernel  metric 256 
    fe80::/64 dev vlan3  proto kernel  metric 256 
    
    root@R1:/# birdc6 show route
    BIRD 1.4.5 ready.
    2001:db8:40:d8::/120 dev vlan216 [ospf1 22:58:08] * I (150/10) [10.40.217.3]
    2001:db8:40::/128  via fe80::aff:fe28:d802 on vlan216 [ospf1 22:58:08] * I (150/20) [10.40.217.0]
    2001:db8:40:2::/120 via fe80::aff:fe28:d802 on vlan216 [ospf1 22:58:08] * I (150/20) [10.40.217.0]
    2001:db8:40:3::/120 dev vlan3 [ospf1 22:57:41] * I (150/10) [10.40.217.1]
    2001:db8:40::3/128 via fe80::aff:fe28:d801 on vlan216 [ospf1 22:58:08] * I (150/20) [10.40.217.3]
    2001:db8:40:d910::/120 via fe80::aff:fe28:d801 on vlan216 [ospf1 22:58:08] * I (150/20) [10.40.217.3]

As you can see, OSPF is running for IPv4 and IPv6, and has discovered the complete internal network of AS64080.

Now make sure you can do the following, or answer the following questions:
 * From H6, `traceroute -n` and `traceroute6 -n` to a few destinations in AS64080 to get acquainted with the network topology.
 * Look at the BIRD logging. A fun way to follow the logging is to do `tail -F R*/rootfs/var/log/bird/*.log` from outside the containers, and then start all of them.
 * Find out why `10.40.217.18` or `2001:db8:40:d910::2` on `R10` cannot be pinged from `R1`, while the route to `10.40.217.16/30` and `2001:db8:40:d910::/120` are actually present in the routing table of `R1` and `R3`.

------------

### TODO:

Zoom in on R3, R10 and add BGP configuration
 * add ebgp protocol
 * meh, umbrella route is not in bird routing table
 * how to add it? static proto, but adding it will result in kernel proto pushing it into FIB
 * keep route administration of ebgp peer in separate table. whoa, bird tables and protocols

## Intermezzo: BIRD tables, protocols, import, export

BIRD concepts:
 * table: multiple routing tables (not like the linux kernel, it's just a collection of routes). e.g. there may be multiple paths to the same network in a table present.
 * protocol: move routes around between tables (pipe) or into / out of BIRD (ospf, bgp)
 * import: draw routes closer to BIRD
 * export: push routes away from BIRD to the outside world
 * table "master": central route table, import = pull to it, export = push away

picture:

    master <-- p_master_to_ebgp_r10 <-- t_ebgp_r10 <-> ebgp_r10
                                                 \ <-- originate_to_r10

 * t\_ebgp\_r10 holds route information about routes originates to r10 and routes that are learned from r10
 * originate\_to\_r10 is a collection of routes that is advertised by this network
 * pipe to master forwards all routes that are learned from the ebgp session
 * master can just export all to kernel

## Let's do it

 * show BIRD config for pipe and table and ebgp
 * reload, show proto, show route export p_blah etc
 * see that routes are imported from the other end
 * see that they end up in master table and in ip r

## Connecting the internal network, not only edge

 * now ebgp router knows route to external network
 * how to tell the ospf network?
 * export the bgp routes to ospf? no!
 * explain ibgp -> tell non-edge-routers about external connectivity
 * ibgp: all routers must have ibgp session with edge routers
 * KEEP BGP IN BGP
 * do it! configure ibgp session between R0, R3
 * R0 can just import the info and put it into kernel table
 * wait what... bgp nexthop? -> first router *outside* the network
 * BGP needs OSPF to provide internal nexthop towards external router -> recap: BGP trusts on OSPF behaviour
 * small link nets for ebgp sessions need to be in IGP!
 * make it work!

## What about the third network?

 * build R1,R2,R3 with 3 containers
 * show AS-path
 * disable link between routers, see traffic being redirected
 * just put some address from the umbrella range on loopback, yolo
