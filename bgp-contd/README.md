BGP, Part II
============

In [BGP, Part I](/bgp-intro/README.md), our knowledge of OSPF to manage routing details inside a network was extended with the ability to connect entire networks together, hiding the detailed topology of one network to the other. Since it was done with a single BGP connection between only two networks, it's time for something more extensive now. Let's throw more networks and some redundancy into the game:

![BGP network with redundant paths](/bgp-contd/bgp-redundancy.png)

In the picture, we see three networks, which are connected by several links that use the BGP protocol to exchange routing information. I've deliberately kept the internal structure of the networks as simple as possible.
 * `AS65000` and `AS65010`, the left and right network, have a redundant link between them. When properly configured, this should make it possible to do maintenance on either of the two connections (e.g. shutting down `R0` and `R10`, or just one of them, or the physical link in between) without any interruption of network traffic between the two networks.
 * The links between `R0` and `R10`, and between `R1` and `R11` are high bandwidth, low latency links.
 * `AS65000` and `AS65010`, the two bigger networks, run OSPF inside, so that e.g. `R2` learns about the subnets that are used for the interconnects to the neighbour networks (to be able to resolve the the BGP next hop on `R2`).
 * `AS65020` is a smaller network, that has only a single gateway connecting it to the outside world. It's connected to both of the bigger networks with links that have a relatively lower bandwidth and higher latency. During the tutorial, we'll make adjustments to the configuration so `AS65020` can still reach both `AS65000` and `AS65010` when one of the external links is down.
 * Ah, and this time it's an IPv6 only example.

## Setting up the example network

Well, you known the drill. :-)

Thankfully, most of the configuration is provided already, so we can quickly set up this whole network using our LXC environment. Just like in the previous tutorials, the birdbase container can be cloned, after which the lxc network information and configuration inside the containers can be copied into them.

 1. Clone this git repository somewhere to be able to use some files from the bgp-contd/lxc/ directory inside.
 2. lxc-clone the birdbase container several times:

        lxc-clone -s birdbase R0
        lxc-clone -s birdbase R1
        lxc-clone -s birdbase R2
        lxc-clone -s birdbase R10
        lxc-clone -s birdbase R11
        lxc-clone -s birdbase R12
        lxc-clone -s birdbase R20

 3. Set up the network interfaces in the lxc configuration. This can be done by removing all network related configuration that remains from the cloned birdbase container, and then appending all needed interface configuration by running the fixnetwork.sh script that can be found in `bgp-contd/lxc/` in this git repository. Of course, have a look at the contents of the script first, before executing it.

        . ./fixnetwork.sh

 4. Copy extra configuration into the containers. The bgp-intro/lxc/ directory inside this git repository contains a little file hierarchy that can just be copied over the configuration of the containers. For each router, it's a network/interfaces configuration file which adds an IP address that corresponds with the Router ID to the loopback interface, and a simple BIRD configuration file that serves as a starting point for our next steps.

 5. Start all containers

        for router in 0 1 2 10 11 12 20; do lxc-start -d -n R$router; sleep 2; done

## Looking around

There's a lot of bird config already in place, which looks like the Part I config, but multiple times for each connection. Take some time to browse through the bird6.conf files on all routers, and make sure you understand what the configuration is doing.

Note: some parts of the configuration are still missing, because we'll be adding them while doing the tutorial. If you can already spot something that is missing now, you get bonus points! :)

On `R2`, inspect the output of `birdc6 show route` and `birdc6 show route all 2001:db8:10::/48`:

    root@R2:/# birdc6 show route
    BIRD 1.4.5 ready.
    2001:db8:20::/48   via fe80::c1a:1aff:fe4d:b889 on ibgp [ibgp_r1 2015-08-07 from 2001:db8::1] * (100/20) [AS65020i]
    2001:db8::ff/128   via fe80::7054:20ff:fe32:2a34 on ibgp [ospf1 2015-08-07] * I (150/20) [10.0.0.0]
    2001:db8:0:5::/120 via fe80::c1a:1aff:fe4d:b889 on ibgp [ospf1 2015-08-07] * I (150/20) [10.0.0.1]
    2001:db8::/48      blackhole [static1 2015-08-07] * (200)
    2001:db8:0:1::/120 dev ibgp [ospf1 2015-08-07] * I (150/10) [10.0.0.2]
    2001:db8::1/128    via fe80::c1a:1aff:fe4d:b889 on ibgp [ospf1 2015-08-07] * I (150/20) [10.0.0.1]
    2001:db8:0:3::/120 via fe80::7054:20ff:fe32:2a34 on ibgp [ospf1 2015-08-07] * I (150/20) [10.0.0.0]
    2001:db8:10:4::/120 via fe80::c1a:1aff:fe4d:b889 on ibgp [ospf1 2015-08-07] * I (150/20) [10.0.0.1]
    2001:db8:10::/48   via fe80::7054:20ff:fe32:2a34 on ibgp [ibgp_r0 19:36:36 from 2001:db8::ff] * (100/20) [AS65010i]
                       via fe80::c1a:1aff:fe4d:b889 on ibgp [ibgp_r1 2015-08-07 from 2001:db8::1] (100/20) [AS65010i]

    root@R2:/# birdc6 show route all 2001:db8:10::/48
    BIRD 1.4.5 ready.
    2001:db8:10::/48   via fe80::7054:20ff:fe32:2a34 on ibgp [ibgp_r0 19:36:36 from 2001:db8::ff] * (100/20) [AS65010i]
            Type: BGP unicast univ
            BGP.origin: IGP
            BGP.as_path: 65010
            BGP.next_hop: 2001:db8:0:3::10
            BGP.local_pref: 100
                       via fe80::c1a:1aff:fe4d:b889 on ibgp [ibgp_r1 2015-08-07 from 2001:db8::1] (100/20) [AS65010i]
            Type: BGP unicast univ
            BGP.origin: IGP
            BGP.as_path: 65010
            BGP.next_hop: 2001:db8:10:4::11
            BGP.local_pref: 100

Notice that `R2` knows two different routes to `2001:db8:10::/48`. One of them gets chosen to end up in the linux kernel routing table (marked with the `*`), and the information about the route shows from which iBGP connection the route was learned.

`lxc-attach` to `R12` and verify the routes to the other two networks from there. Some additional `traceroute6 -n` to some destinations in remote networks might help.

    root@R2:/# traceroute6 -n 2001:db8:10::12
    traceroute to 2001:db8:10::12 (2001:db8:10::12), 30 hops max, 80 byte packets
     1  2001:db8:0:1::ff  0.470 ms  0.461 ms  0.463 ms
     2  2001:db8:0:3::10  0.729 ms  0.727 ms  0.638 ms
     3  2001:db8:10::12  0.935 ms  0.962 ms  0.868 ms

 * look at the route to 2001:db8:20::/48 from R2 -> only connected to R1, one option, notice next-hop
 * traceroute -n from R2 to R20

        root@R2:/# traceroute6 -n 2001:db8:20::20
        traceroute to 2001:db8:20::20 (2001:db8:20::20), 30 hops max, 80 byte packets
         1  2001:db8:0:1::1  0.384 ms  0.353 ms  0.334 ms
         2  2001:db8:20::20  0.319 ms  0.345 ms  0.252 ms

## Redundancy

 * 2 connections between `AS65000` and `AS65010`
 * in order not to interrupt traffic in case of a partial outage or maintenance, traffic can move to the other connection
 * look at `root@R2:/# mtr -n 2001:db8:10::12`
 * in my case over `R0`, `R10`
 * go to `R0`, `birdc6`, `show protocols` and `disable ebgp_r10`
 * look what happens to the mtr, and look at `/var/log/bird/bird6.log`
 * now look at R1, does it see a route to AS65010? no? why? fix it.

## Peering

 * simply the fact that two networks have an interconnect and exchange prefixes

## Redundancy for the branch office

 * two connections, disable to R1, whoops, not reachable from AS65000 any more
 * would be nice to


## Transit

 * announcing received routes again to another AS
 * by default BGP will choose the shortest AS path

## Assignments

## Bonus

 * local preference (> AS path!)
 * med -> derive from next hop igp? also, potatoes


