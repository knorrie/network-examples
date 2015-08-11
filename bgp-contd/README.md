BGP, Part II
============

Bla blah, previous BGP Part I shows two networks, 1 single BGP link.

This tutorial, Part II: multiple networks with multiple connections to each other

![BGP network with redundant paths](/bgp-contd/bgp-redundancy.png)

 - two main locations (HQ office, datacenter)
 - a branch office
 - high bandwidth connections between two main locations, low bandwidth to branch office
 - IPv6-only example this time

## Look around

Lots 'o bird config already in place, which looks like the Part I config, but multiple times for each connection.

 * R2: `birdc6 show route`, `birdc show route all <prefix>`
 * look at the route to 2001:db8:10::/48 from R2 -> two options, one is chosen and ends up in kernel (with the `*`)
 * look at the route to 2001:db8::/48 from R12 -> same story, either R10 or R11
 * each AS decides where it sends the traffic, does not have to be the same connection!
 * traceroute -n from R2 to R12:

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


