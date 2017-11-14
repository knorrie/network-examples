BGP, Part II
============

In [BGP, Part I](/bgp-intro/README.md), our knowledge of OSPF to manage routing details inside a network was extended with the ability to connect entire networks together, hiding the detailed topology of one network to the other. Since it was done with a single BGP connection between only two networks, it's time for something more extensive now. Let's throw more networks and some redundancy into the game:

![BGP network with redundant paths](/bgp-contd/bgp-redundancy.png)

Hint: print this picture so you can make notes on it and keep it in sight during the tutorial!

In the picture, we see three networks, which are connected by several links that use the BGP protocol to exchange routing information. I've deliberately kept the internal structure of the networks as simple as possible.
 * `AS65000` and `AS65010`, the left and right network, have a redundant link between them. When properly configured, this should make it possible to do maintenance on either of the two connections (e.g. shutting down `R0` and `R11`, or just one of them, or the physical link in between) without any interruption of network traffic between the two networks.
 * The links between `R0` and `R11`, and between `R1` and `R10` are high bandwidth, low latency links.
 * `AS65000` and `AS65010`, the two bigger networks, run OSPF inside, so that e.g. `R2` learns about the subnets that are used for the interconnects to the neighbour networks (to be able to resolve the the BGP next hop on `R2`).
 * `AS65020` is a smaller network, that has only a single gateway connecting it to the outside world. It's connected to both of the bigger networks with links that have a relatively lower bandwidth and higher latency. During the tutorial, we'll make adjustments to the configuration so `AS65020` can still reach both `AS65000` and `AS65010` when one of the external links is down.
 * Ah, and this time it's an IPv6 only example.

## Setting up the example network

Well, you know the drill. :-)

Thankfully, most of the configuration is provided already, so we can quickly set up this whole network using our LXC environment. Just like in the previous tutorials, the birdbase container can be cloned, after which the lxc network information and configuration inside the containers can be copied into them.

 1. Clone this git repository somewhere to be able to use some files from the bgp-contd/lxc/ directory inside:

        cd ~
        git clone https://github.com/knorrie/network-examples.git

 2. lxc-copy the birdbase container several times:

        for router in 0 1 2 10 11 12 20; do lxc-copy -s -n birdbase -N R$router; done

 3. Set up the network interfaces in the lxc configuration. This can be done by removing all network related configuration that remains from the cloned birdbase container, and then appending all needed interface configuration by running the fixnetwork.sh script that can be found in `bgp-contd/lxc/` in this git repository. Of course, have a look at the contents of the script first, before executing it.

        cd /var/lib/lxc
        /bin/bash ~/network-examples/bgp-contd/lxc/fixnetwork.sh

 4. Copy extra configuration into the containers. The bgp-contd/lxc/ directory inside this git repository contains a little file hierarchy that can just be copied over the configuration of the containers. For each router, it's a network/interfaces configuration file whcih adds an IP address that corresponds with the Router ID to the loopback interface, and a simple BIRD configuration file that serves as a starting point for our next steps:

        cp ~/network-examples/bgp-contd/lxc/R* . -r

 5. Start all containers

        for router in 0 1 2 10 11 12 20; do echo "Starting R${router}..."; lxc-start -d -n R$router; sleep 2; done

## Looking around...

There's a lot of bird config already in place, which looks like the Part I config, but multiple times for each connection. Take some time to browse through the bird6.conf files on all routers, so you can grasp the idea of how the configuration is set up. Hint: you can also do this from outside the lxc containers, so you can easily open multiple files and compare them.

Note: some parts of the configuration are still missing, because we'll be adding them while doing the tutorial. If you can already spot something that is missing now, you receive some bonus points! :)

### ...from the viewpoint of R2

`lxc-attach` to `R2` and verify the routes to the other two networks from there. It might take a few extra seconds after starting all the containers for them to figure out the complete network topology and set up all routing protocol sessions and exchange all routing information.

 * Do a `birdc6 show route` and `birdc6 show route all 2001:db8:10::/48`.
 * `traceroute 2001:db8:10::12` to `R12` in `AS65010`
 * Look at the route from `R2` to `R20`: `birdc6 show route all 2001:db8:20::/48`
 * `traceroute 2001:db8:20::20` to `R20` in `AS65020`

The output of the commands should show that `R2` knows two different routes to `2001:db8:10::/48`. One of them gets chosen to end up in the linux kernel routing table (marked with the `*`), and the information about the route shows from which ibgp connection the route was learned. In my case here it's the route learned from the ibgp session `ibgp_r0` that gets chosen, but it might as well be the one via `R1` in your case.

For traffic to `R20`, there's only one route shown from the viewpoint of `R2`, which is pointing to `R1`, since this is the only router in the local network that has a connection to the remote `AS65020`.

## Asymmetric traffic flows

Since there are two active network paths between `AS65000` and `AS65010`, each of the networks is free to choose which connection to use to send traffic to the other network.

Let's do some traceroute again, to look at traffic flow between `R2` and `R12`:

    root@R2:/# traceroute r12
    traceroute to r12 (2001:db8:10::12), 30 hops max, 80 byte packets
     1  lan.r0 (2001:db8:0:1::ff)  0.384 ms  0.385 ms  0.389 ms
     2  ebgp_r0.r11 (2001:db8:0:3::11)  0.565 ms  0.577 ms  0.490 ms
     3  lo.r12 (2001:db8:10::12)  1.081 ms  1.012 ms  1.014 ms

    root@R12:/# traceroute r2
    traceroute to r2 (2001:db8::2), 30 hops max, 80 byte packets
     1  lan.r10 (2001:db8:10:2::10)  0.292 ms  0.290 ms  0.369 ms
     2  ebgp_r10.r1 (2001:db8:10:4::1)  0.435 ms  0.375 ms  0.392 ms
     3  lo.r2 (2001:db8::2)  0.829 ms  0.785 ms  0.770 ms

Thanks to the information in the `/etc/hosts` file in the containers, the output shows us the names of the network interfaces that correspond to the used addresses.

As you can see, `R2` chooses to send traffic over `R0` as next hop, which will forward it to `R11` to get it into `AS65010`. In the meantime, traffic in the other direction chooses the path over `R10` and `R1`. When receiving traffic, a router has no idea of the path that a packet has traveled along before arriving. When sending traffic back, the router will just use its own thoughts about the best path towards that destination, which might mean choosing an outgoing network interface that is different from the one the packet it's responding to was received on.

_Understanding asymmetric traffic flow is essential in the process of debugging network troubles in a larger network._

Let me give you an example why. Say, you're debugging latency on a connection to a remote host (look at the rtt measurements):

    root@R2:/# traceroute r12
    traceroute to r12 (2001:db8:10::12), 30 hops max, 80 byte packets
     1  lan.r0 (2001:db8:0:1::ff)  0.389 ms  0.389 ms  0.398 ms
     2  ebgp_r0.r11 (2001:db8:0:3::11)  0.614 ms  0.572 ms  0.525 ms
     3  lo.r12 (2001:db8:10::12)  101.208 ms  101.121 ms  101.142 ms

When you're not aware of the possibility of asymmetric traffic flows, you could incorrectly assume that there's a problem with the network link between `R11` and `R12`, because of the introduced extra latency. However, there might be multiple other possibilities, since you do not know which route the traffic from `R12` back to you takes. In our little example network we know, since we just found out by looking at it from both ends. It could as well be the link between `R12` and `R10`, or between `R10` and `R1`, or even between `R1` and `R2`...

Let's have a look at a trace from the other end back to `R2`:

    root@R12:/# traceroute r2
    traceroute to r2 (2001:db8::2), 30 hops max, 80 byte packets
     1  lan.r10 (2001:db8:10:2::10)  0.402 ms  0.341 ms  0.330 ms
     2  ebgp_r10.r1 (2001:db8:10:4::1)  200.490 ms  200.472 ms  200.453 ms
     3  lo.r2 (2001:db8::2)  101.053 ms  101.039 ms  101.020 ms

Router `R10` can be reached just fine, but the next step (`ebgp_r10.r1` is the network interface on `R1` that is looking at `R10`) shows quite some introduced latency. Since the shortest route from `R1` back to `R12` is by sending it back to `R10` directly, the total round trip in the second step shows twice the amount of extra latency, while the total round trip time for reaching `R2` only shows the introduced latency once.

Here's an edited version of the traceroute output, with the paths mentioned:

    root@R2:/# traceroute r12
    traceroute to r12 (2001:db8:10::12), 30 hops max, 80 byte packets
     1  lan.r0       r2 -> r0 (ttl expired), r0 -> r2
     2  ebgp_r0.r11  r2 -> r0 -> r11 (ttl expired), r11 -> r0 -> r2
     3  lo.r12       r2 -> r0 -> r11 -> r12 (destination), r12 -> r10 -> r1 -> r2

    root@R12:/# traceroute r2
    traceroute to r2 (2001:db8::2), 30 hops max, 80 byte packets
     1  lan.r10      r12 -> r10 (ttl expired), r0 -> 12
     2  ebgp_r10.r1  r12 -> r10 -> r1 (ttl expired), r1 -> r10 -> r12
     3  lo.r2        r12 -> r10 -> r1 -> r2 (destination), r2 -> r0 -> r11 -> r12

Introducing latency for test purposes can be done with the linux traffic control tooling. Here's the two commands I just used on `R1` and `R10` to achieve the effect shown above:

    root@R1:/# tc qdisc add dev ebgp_r10 root netem delay 100ms
    root@R10:/# tc qdisc add dev ebgp_r1 root netem delay 100ms

## Playing with redundant paths

Having redundancy in the network has the advantage that the network can survive a partial outage, which can be either planned (maintenance) or unplanned (failure of a component):

![BGP network with an inactive path](/bgp-contd/bgp-redundancy-ibgp-r0-r1.png)

### Moving around traffic

By disabling the BGP session on `R0` towards `R11`, we can force traffic between `AS65000` and `AS65010` to choose the route over `R1` and `R10` instead:

    root@R0:/# birdc6
    BIRD 1.4.5 ready.

    bird> show protocols 
    name     proto    table    state  since       info
    kernel1  Kernel   master   up     15:07:17    
    device1  Device   master   up     15:07:17    
    ospf1    OSPF     master   up     15:07:17    Running
    static1  Static   master   up     15:07:17    
    p_master_to_bgp Pipe     master   up     15:07:17    => t_bgp
    originate_to_r11 Static   t_r11    up     15:07:17    
    ebgp_r11 BGP      t_r11    up     15:07:34    Established   
    p_bgp_to_r11 Pipe     t_bgp    up     15:07:17    => t_r11
    ibgp_r2  BGP      t_bgp    up     15:08:17    Established   

    bird> disable ebgp_r11
    ebgp_r11: disabled

When doing some `mtr` from `R2` to `R12`, you can see the path switch over to the other connection, while disabling the eBGP session on `R0`:

    root@R2:/# mtr r12

                                 My traceroute  [v0.85]
    R2 (::)                                                Sun Nov 29 15:30:58 2015
    Keys:  Help   Display mode   Restart statistics   Order of fields   quit
                                           Packets               Pings
     Host                                Loss%   Snt   Last   Avg  Best  Wrst StDev
     1. 2001:db8:0:1::ff                  0.0%    36    0.1   0.1   0.1   0.5   0.0
        2001:db8:0:1::1
     2. 2001:db8:0:3::11                  0.0%    36    0.1   0.1   0.1   0.4   0.0
        2001:db8:10:4::10
     3. 2001:db8:10::12                   0.0%    35    0.1   0.1   0.1   0.5   0.0

Also, the bird6 log file in `/var/log/bird/bird6.log` shows that bird gets an update from the iBGP session to `R0` about the fact that the route to `2001:db8:10::/48` over `R0` should no longer be used, following by a replacement of the route in the linux kernel, pointing to `R1` instead:

    ibgp_r0 > removed [replaced] 2001:db8:10::/48 via fe80::4ef:8ff:fe02:cef6 on lan
    kernel1 < replaced 2001:db8:10::/48 via fe80::bc5d:a8ff:fee4:c062 on lan

Note that shutting down a BGP session only will stop the exchange of routing information. The link itself is not disabled in this example. This means that if for whatever reason (like manual configuration of routes) traffic would arrive over this link, it would still happily be handled by the linux kernel.

### Fixing iBGP

As I said a little earlier, there is still some configuration missing, although we didn't spot it yet it seems. Well, if you try to reach any router in `AS65010` from `R0`, you will see it fail:

    root@R0:/# traceroute r11
    traceroute to r11 (2001:db8:10::11), 30 hops max, 80 byte packets
    connect: Network is unreachable

Also, `R20` is not reachable from `R0`, while the connection between `AS65000` and `AS65020` is still active...

    root@R0:/# traceroute r20
    traceroute to r20 (2001:db8:20::20), 30 hops max, 80 byte packets
    connect: Network is unreachable

In the BGP introduction tutorial, we learned that iBGP sessions are used to share information about reachability of remote networks, outside of the own AS. By setting up an iBGP connection between `R2` and both `R0` and `R1`, we can make sure that `R2` is kept up to date about a path to external networks that are connected via `R0` and `R1`. However, the same has to be done between `R0` and `R1` to make sure that it knows an alternative route to the remote network `AS65010` when its own connection to it is down, and also knows to reach `AS65020` using `R1`.

### Assignments

Now, do the following things:
 * Add iBGP configuration to share BGP routes between `R0` and `R1`, and also between `R10` and `R11`. Pay special attention to the `import` and `export` rules. Use e.g. `show route protocol ibgp_r0` on `R1` to verify that it's receiving information about external routes.

        bird> show route protocol ibgp_r0
        2001:db8:10::/48   via fe80::4ef:8ff:fe02:cef6 on lan [ibgp_r0 23:24:03 from 2001:db8::ff] (100/20) [AS65010i]
        bird> show route export ibgp_r0
        2001:db8:20::/48   via 2001:db8:0:5::20 on ebgp_r20 [ebgp_r20 2015-11-28] * (100) [AS65020i]
        2001:db8:10::/48   via 2001:db8:10:4::10 on ebgp_r10 [ebgp_r10 2015-11-28] * (100) [AS65010i]

 * Check that you can reach every external network from every router in all of the three networks. You can use the script bgp-contd/lxc/check_connectivity.sh too check that every router can ping every router.
 * Try disabling some of the links between routers by using the `disable`/`enable` commands on the bird command line, and check if you still can reach all parts of the AS65000 and AS65010.
 * Change `import` and `export` filters in the `protocol bgp ebgp_r*` sections in `bird6.conf` so that you end up with a situation where all traffic is forced into an asymmetric traffic pattern in which traffic from `AS65000` to `AS65010` has to leave via `R1` to `R10`, and traffic back flows over `R11` to `R0`. Verify the changes seen in bird `show route all` output when you change filters.

## A closer look at the BIRD configuration

Here's a picture of the tables and protocols used in the BIRD configuration of `R1`:

![BIRD protocols, tables, import and export](/bgp-contd/bird-prototable.png)

As you might have noticed, I prefer using multiple internal routing tables in BIRD in favor of less complex filters. Since we're dealing with a very limited number of routes it's not a problem at all that a lot of routes are duplicated in multiple tables.

If you compare this drawing to the previous one from the BGP Introduction tutorial, you'll notice an extra table, in between the eBGP sessions and the master table. Here's the corresponding part from `bird6.conf`:

    ##############################################################################
    # BGP table
    #

    # Use this routing table to gather external routes received via BGP which we
    # want push to the kernel via our master table and to other routers in our AS
    # via iBGP or even to other routers outside our AS again (transit), which can
    # be connected here or to a router elsewhere on the border of our AS.

    table t_bgp;

    protocol pipe p_master_to_bgp {
        table master;
        peer table t_bgp;
        import all;  # default
        export none;  # default
    }

eBGP sessions are connected to `t_bgp` via an intermediate table for their own, which is used to insert routes that are originated from our own AS that we want to announce to the other side. iBGP sessions are connected to the `t_bgp` directly, as they just need to share the collection of externally learned routes with routers inside the network.

### Assignments

 * Compare the drawing with the configuration file of `R1`.

## Redundancy for the branch office: Transit traffic

The following picture is the same as the one at the beginning of this page:

![BGP network with redundant paths](/bgp-contd/bgp-redundancy.png)

Until now, we have ignored the top network, with `R20` in it. Let's have a better look at this part now. `AS65020` is connected to both of the other networks with a single connection.

What would the result be for the connectivity of `AS65020` if one of those links would be down because of maintenance or a defect? We can do some tests to find out.

First make sure you can reach `R20` from `R10`:

    root@R10:/# traceroute r20
    traceroute to r20 (2001:db8:20::20), 30 hops max, 80 byte packets
     1  lan.r11 (2001:db8:10:2::11)  0.901 ms  0.883 ms  0.868 ms
     2  lo.r20 (2001:db8:20::20)  0.897 ms  0.804 ms  0.803 ms

Next, shut down eBGP between `R11` and `R20`, and see what happens...

    root@R11:/# birdc6
    BIRD 1.4.5 ready.
    bird> disable ebgp_r20
    ebgp_r20: disabled

    root@R10:/# traceroute r20
    traceroute to r20 (2001:db8:20::20), 30 hops max, 80 byte packets
    connect: Network is unreachable

There's still an open network path to `R20`, via `R1`. But, `R10` is not aware of this, because the routers in `AS65000` do not tell the ones in `AS65010` that they also know a path to `R20`...

    root@R1:/# birdc6
    BIRD 1.4.5 ready.
    bird> show route table t_bgp
    2001:db8:20::/48   via 2001:db8:0:5::20 on ebgp_r20 [ebgp_r20 20:47:42] * (100) [AS65020i]
    2001:db8:10::/48   via 2001:db8:10:4::10 on ebgp_r10 [ebgp_r10 2015-11-28] * (100) [AS65010i]
                       via fe80::4ef:8ff:fe02:cef6 on lan [ibgp_r0 2015-12-01 from 2001:db8::ff] (100/20) [AS65010i]
    bird> show route export ebgp_r10
    2001:db8::/48      blackhole [originate_to_r10 2015-11-28] * (200)

As seen above in the configuration diagram, the routers that connect to external networks in `AS65000` and `AS65010` collect all external routes in their BIRD `t_bgp` table, so they can be sent over iBGP to the other routers in their network. However, as you can see in the `bird6.conf` configuration files of them, the routes in `t_bgp` are not exported again to external peers.

### Assignments

![BGP Transit](/bgp-contd/bgp-redundancy-transit1.png)

 * Change the BIRD configuration of `R1` so that externally learned routes are exported again to other external networks. The routes are available in the `t_bgp` table, and can simply all be exported again towards `R10` and `R20`. Now check that you can already reach `R20` from `R10` with a traceroute, which means that `R20` also knows a path back to `R10` now:

        root@R10:/# traceroute r20
        traceroute to r20 (2001:db8:20::20), 30 hops max, 80 byte packets
         1  ebgp_r10.r1 (2001:db8:10:4::1)  0.330 ms  0.317 ms  0.309 ms
         2  lo.r20 (2001:db8:20::20)  0.441 ms  0.432 ms  0.405 ms

 * In the logfiles in `/var/log/bird/bird6.log` on `R20`, `R1` and `R10` you should see that the extra routing information was received, and how bird processed the routes internally. Pay some attention to the 'ignored', 'filtered' and 'rejected by protocol' lines. They show that the defined filters are used, and they also show that bird will by default be clever about not pushing routes back through a pipe or protocol it just learned them from, which simplifies the filter definitions a lot, since we can just use 'all' for exporting from `t_bgp` to e.g. `t_r20`.
 * On `R1`, check `show route export ebgp_r10` and `show route export ebgp_r20`.
 * Adjust the other three routers in the same way: `R0`, `R10` and `R11`. Don't change `R20`, since we do not want `AS65020`, with its two slow low-bandwith links to be a transit area for traffic between `AS65000` and `AS65010`. Those two networks already have fast redundant links between them.
 * Enable the BGP session between `R11` and `R20` again, and notice that the routing immediately switches back to using this path.
 * Disable the network path between `R1` and `R20`, and make sure you can still reach `R20` from `R2`.

### Extra assignment

Instead of disabling a whole BGP session between routers to stop using a particular path, it's also possible to keep the BGP connection alive, and just stop originating prefixes or re-announcing them if we're a transit network, but still accept them from the remote or just the other way around. When doing so we can configure a situation with an asymmetric traffic flow.

![BGP Transit fun assignment](/bgp-contd/bgp-redundancy-transit2.png)

 * Without disabling any BGP session, change the filters configuration so that traffic flow between `R10` and `R20` is as shown in the picture above:

        root@R10:/# traceroute r20
        traceroute to r20 (2001:db8:20::20), 30 hops max, 80 byte packets
         1  lan.r11 (2001:db8:10:2::11)  0.068 ms  0.018 ms  0.016 ms
         2  ebgp_r11.r0 (2001:db8:0:3::ff)  0.380 ms  0.356 ms  0.341 ms
         3  ebgp_r10.r1 (2001:db8:10:4::1)  0.462 ms  0.458 ms  0.388 ms
         4  lo.r20 (2001:db8:20::20)  0.401 ms  0.409 ms  0.435 ms

        root@R20:/# traceroute r10
        traceroute to r10 (2001:db8:10::10), 30 hops max, 80 byte packets
         1  ebgp_r20.r11 (2001:db8:10:6::11)  0.073 ms  0.019 ms  0.018 ms
         2  lo.r10 (2001:db8:10::10)  0.320 ms  0.268 ms  0.245 ms

 * Notice that this is actually a stupid way to prefer specific routes for traffic, because by disabling BGP sessions or by not announcing or not accepting routes, we reduce redundancy in the network, because the disabled paths also do not function as less-preferable path any more. See BGP route selection below for more thoughts about this.

## Bonus material

Now you've learned the basics of building a network with BGP, you should be able to better understand the average "BGP introduction" page published on the Internet that immediately tries to overwhelm you with technical terms instead of just providing an example. ;-]

The following topics are also a minimal set of hints for further study:

### Peering and Transit

In the above examples, we've already seen the difference between just connecting two networks so they can reach each other, and on top of that, forwarding route announcements, so that a network can act as transit area for traffic between two other networks. These concepts are called "Peering" and "Transit" and if you search for them, you should be able to find a lot more information.

The next page of this tutorial, [Routing on the internet](/the-internet/README.md), will be about discovering the fact that with the limited knowledge we have now, it's already possible to understand how the whole internet works together. The page hasn't been written yet, but will show how networks of ISPs, Transit Providers and Internet Exchanges connect the whole world together and how you can find out using tools on the internet how they're connected, and how they provide a path between your own computer to every remote destination on the internet you're connecting to every day.

### BGP route selection

As hinted above ("Notice that this is actually a stupid way...") there are smarter ways to prefer specific network paths for specific routes than to just disable a path or stop accepting announcements. BGP has a bunch of knobs to adjust that you can combine to create a routing policy inside your own AS.

In the BIRD documentation about BGP, you can find a list about "Route selection rules" that BIRD applies to select which BGP route to a particular destination will be chosen if multiple ones are available for the same prefix:

 * Prefer route with the highest Local Preference attribute.
 * Prefer route with the shortest AS path.
 * Prefer IGP origin over EGP and EGP origin over incomplete.
 * Prefer the lowest value of the Multiple Exit Discriminator.
 * Prefer routes received via eBGP over ones received via iBGP.
 * Prefer routes with lower internal distance to a boundary router.
 * Prefer the route with the lowest value of router ID of the advertising router.

Using other resources on the internet you should be able to find out what all of these mean. Using the BIRD documentation, you can change the configuration of all routers in our example network to route traffic around in different ways using these options.

Within a single AS, it's really important to have a single policy, so that all routers are on the same page about where to send traffic. You cannot have two border routers, which independently from each other determine that the other one should be used as exit point to a specific external peer. They would pingpong all traffic between them until the IP packet TTL expires and then drop the traffic, resulting in a big black hole and a bunch of overloaded internal connections. So, yes, this can get quite complex quickly if you start to make customizations.

Remember that we started this tutorial with an example network in which traffic between `AS65000` and `AS65010` was already using the two paths between them in an asymmetric way. Because the setup of both networks is so similar and mirrored, the fact that traffic back and forth flows asymmetrically is actually thanks to the last rule: "Prefer the route with the lowest value of router ID of the advertising router.". After initially setting up the example, I had to swap `R10` and `R11` again to get this behaviour. :-)
