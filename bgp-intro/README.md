BGP, Part I
===========

In the previous tutorial, we discovered how to let [OSPF](/ospf-intro/README.md) dynamically configure routing inside a network. This tutorial provides an introduction to another routing protocol, which is BGP, the Border Gateway Protocol. As the name implies, this protocol acts on the border of a network. Where OSPF is well suited to keep track of all tiny details of what's happening in our internal network, BGP will be talking to the outside world to interconnect our network with other networks, managed by someone else.

## BGP Essentials

When routers talk BGP to each other, they essentially just claim that network ranges are reachable via them:

![BGP network, barebones](/bgp-intro/bgp-heythere.png)

Let's look at the same picture again, hiding less information:

![BGP network, less simplified](/bgp-intro/bgp-hey2.png)

The picture shows two networks, which are interconnected through router `R3` and `R10`.

 * A complete network under control of somebody has an AS ([Autonomous System](https://tools.ietf.org/html/rfc1930)) number. This number will be used later in the BIRD BGP configuration.
 * The routes that are published to another network are as aggregated as possible, to minimize the amount of them. While the internal routing table in for example `AS64080` might contain dozens of prefixes, for each little vlan, and probably a number of single host routes (IPv4 `/32` and IPv6 `/128`), they're advertised to the outside as just three routes in total.
 * If neighbouring routers between different networks are directly connected, they often interconnect using a minimal sized network range. For IPv4, this is usually a `/30` and for IPv6 a `/120` or a `/126` prefix, containing only the two routers. In the example above, the small network ranges are taken from the network of `AS64080`.

## OSPF vs. BGP

While the title of this section might seem logical, since we're considering BGP after just having spent quite some time on OSPF, it's actually a non-issue. OSPF and BGP are two very different routing protocols, which are used to get different things done. Nonetheless, let's look at some differences:

OSPF:
 * Routes in the network are originated by just putting ip addresses on a network interface of a router, and letting the routing protocol pick them up automatically.
 * The routes in OSPF are addresses and subnets that are actually in use.
 * Every router that participates in the OSPF protocol has a full detailed view on the network using link state updates that are broadcasted over the network. This knowledge is used to calculate the shortest path to every part of the network.

BGP:
 * Routes that are published to other networks are "umbrella ranges", which are as big as possible and are defined manually.
 * There is no actual proof that the addresses which are advertised are actually in use inside the network.
 * A neighbour BGP router knows that some prefix is reachable via another network, but where OSPF shortest path deals with knowledge about all separate routers, paths and weights, BGP just looks on a higher level, considering a complete network (AS) being one step. By default BGP also tries to forward traffic into the direction that contains the smallest amount of AS-hops to a destination (the shortest AS-path), but BGP provides a fair amount of configurable options to influence the routing decisions.

So, OSPF is an IGP (Interior Gateway Protocol) and BGP is an EGP (Exterior Gateway Protocol). BGP can connect OSPF networks to each other, hiding a lot of detail inside them.

## BGP and OSPF with BIRD: Setting up the containers and networks

In the second half of this tutorial we'll configure a network, using OSPF, BGP and the BIRD routing software. BGP wise, it's kept simple, using just a single connection between two networks.

![BGP and OSPF network](/bgp-intro/bgp-ospf.png)

Our networks start to look serious now! It might be handy to print this image so you don't have to scroll back up all the time, comparing all the routes in the output of commands with the network topology.

Thankfully, most of the configuration is provided already, so we can quickly set up this whole network using our LXC environment. Just like in the previous tutorial, the birdbase container can be cloned, after which the lxc network information and configuration inside the containers can be copied into them.

 1. Clone this git repository somewhere to be able to use some files from the bgp-intro/lxc/ directory inside:

        cd ~
        git clone https://github.com/knorrie/network-examples.git

 2. lxc-copy the birdbase container several times:

        lxc-copy -s -n birdbase -N R0
        lxc-copy -s -n birdbase -N R1
        lxc-copy -s -n birdbase -N R3
        lxc-copy -s -n birdbase -N R10
        lxc-copy -s -n birdbase -N R11
        lxc-copy -s -n birdbase -N R12
        lxc-copy -s -n birdbase -N H6
        lxc-copy -s -n birdbase -N H7
        lxc-copy -s -n birdbase -N H19
        lxc-copy -s -n birdbase -N H34

 3. Set up the network interfaces in the lxc configuration. This can be done by removing all network related configuration that remains from the cloned birdbase container, and then appending all needed interface configuration by running the fixnetwork.sh script that can be found in `bgp-intro/lxc/` in this git repository. Of course, have a look at the contents of the script first, before executing it.

        cd /var/lib/lxc
        /bin/bash ~/network-examples/bgp-intro/lxc/fixnetwork.sh

 4. Copy extra configuration into the containers. The bgp-intro/lxc/ directory inside this git repository contains a little file hierarchy that can just be copied over the configuration of the containers. For each router, it's a network/interfaces configuration file which adds an IP address that corresponds with the Router ID to the loopback interface, and a simple BIRD configuration file that serves as a starting point for our next steps.

        cp ~/network-examples/bgp-intro/lxc/R* . -r

5. Start all containers

        for router in 0 1 3 10 11 12; do lxc-start -d -n R$router; sleep 2; done
		for host in 6 7 19 34; do lxc-start -d -n H$host; sleep 2; done

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

As you can see, OSPF is running for IPv4 and IPv6, and has discovered the complete internal network of `AS64080`.

Now make sure you can do the following, and answer the following questions:
 * From H6, `traceroute -n` and `traceroute6 -n` to a few destinations in `AS64080` to get acquainted with the network topology.
 * Look at the BIRD logging. A fun way to follow the logging is to do `tail -F R*/rootfs/var/log/bird/*.log` from outside the containers, and then start all of them.
 * Find out why `10.40.217.18` or `2001:db8:40:d910::2` on `R10` cannot be pinged from `R1`, while the route to `10.40.217.16/30` and `2001:db8:40:d910::/120` are actually present in the routing table of `R1` and `R3`.

## BIRD BGP configuration

Let's zoom in a bit first, and focus on the connection between `R3` and `R10`. This section will show how to configure the actual BGP connection between those two routers, so they will learn about each others network.

![BGP and OSPF network, zoom in on R3, R10](/bgp-intro/bgp-ospf-zoom.png)

The routing table of `R3` contains information about the internal network of its own network, `AS64080`. As you can see, routes to the ranges in `AS65033` are missing.

    root@R3:/# ip r
    10.40.2.0/24 via 10.40.216.2 dev vlan216  proto bird 
    10.40.3.0/24 via 10.40.216.3 dev vlan216  proto bird 
    10.40.216.0/28 dev vlan216  proto kernel  scope link  src 10.40.216.1 
    10.40.217.0 via 10.40.216.2 dev vlan216  proto bird 
    10.40.217.1 via 10.40.216.3 dev vlan216  proto bird 
    10.40.217.16/30 dev vlan217  proto kernel  scope link  src 10.40.217.17 
    
    root@R3:/# ip -6 r
    2001:db8:40:: via fe80::aff:fe28:d802 dev vlan216  proto bird  metric 1024 
    2001:db8:40::1 via fe80::aff:fe28:d803 dev vlan216  proto bird  metric 1024 
    unreachable 2001:db8:40::3 dev lo  proto kernel  metric 256  error -101
    2001:db8:40:2::/120 via fe80::aff:fe28:d802 dev vlan216  proto bird  metric 1024 
    2001:db8:40:3::/120 via fe80::aff:fe28:d803 dev vlan216  proto bird  metric 1024 
    2001:db8:40:d8::/120 dev vlan216  proto kernel  metric 256 
    2001:db8:40:d910::/120 dev vlan217  proto kernel  metric 256 
    fe80::/64 dev vlan216  proto kernel  metric 256 
    fe80::/64 dev vlan217  proto kernel  metric 256 

Now, add the following configuration to `bird.conf` of `R3`:

    ##############################################################################
    # eBGP R10
    #
    
    table t_r10;
    
    protocol static originate_to_r10 {
        table t_r10;
        import all;  # originate here
        route 10.40.0.0/22 blackhole;
        route 10.40.216.0/21 blackhole;
    }
    
    protocol bgp ebgp_r10 {
        table t_r10;
        local    10.40.217.17 as 64080;
        neighbor 10.40.217.18 as 65033;
        import filter {
            if net ~ [ 10.0.0.0/8{19,24} ] then accept;
            reject;
        };
        import keep filtered on;
        export where source = RTS_STATIC;
    }
    
    protocol pipe p_master_to_r10 {
        table master;
        peer table t_r10;
        import where source = RTS_BGP;
        export none;
    }

### A closer look

Let me explain a bit about what's going on here. So far, we've used the BIRD protocol types `kernel`, `device` and `ospf`. This configuration snippet introduces three other ones: `static`, `bgp` and `pipe`. Besides that, there's also a table definition on top.

    table t_r10;

By issuing `table t_r10`, we tell BIRD that we'd like to use an extra internal routing table with the name `t_r10`. By default, BIRD always has a routing table named `master`, and now we added a second one. Routing tables in BIRD are just a collection of routes, having some attributes.

    protocol static originate_to_r10 {
        table t_r10;
        import all;  # originate here
        route 10.40.0.0/22 blackhole;
        route 10.40.216.0/21 blackhole;
    }

The static protocol is used to generate a collection of static routes. In this case, we define a protocol static with name `originate_to_r10`, and connect it to table `t_r10`. The import statement causes the routes that are generated by this static route protocol to be imported into the `t_r10` table. Static routes usually have a target of a neighbor router, using a via statement, but in this case, we don't care about a next hop, since it's just a collection of some prefixes that will be exported via BGP. The blackhole won't be actually used for anything here.

    protocol bgp ebgp_r10 {
        table t_r10;
        local    10.40.217.17 as 64080;
        neighbor 10.40.217.18 as 65033;
        import filter {
            if net ~ [ 10.0.0.0/8{19,24} ] then accept;
            reject;
        };
        import keep filtered on;
        export where source = RTS_STATIC;
    }

The bgp protocol is named after the router which it's talking to, `R10`, and is also connected to the `t_r10` routing table inside BIRD. It has a local and remote IP address and AS number. The import rules are a bit more complex than a simple `import all`, which also would have been sufficient here to get it working. The filter shown here just makes sure only RFC1918 prefixes from `10/8` are accepted, which are allowed to be from a `/19` to `/24` in size each. The export rule contains a simple filter that tells BIRD to push all routes from table `t_r10` that originate from a static protocol to the outside, to `R10`.

    protocol pipe p_master_to_r10 {
        table master;
        peer table t_r10;
        import where source = RTS_BGP;
        export none;
    }

The pipe protocol is a simple protocol that is able to move around routes between internal BIRD routing tables. In this case, the pipe protocol `p_master_to_r10` is connected to the central `master` routing table and is looking at table `t_r10`. From table `t_r10`, all routes that originate from an external BGP peer are imported into the master table. Doing so will cause the routes that will be learned from the remote network to end up in the routing table of the Linux kernel (via the kernel protocol that exports them from the BIRD master table outside BIRD), while the routes that only were meant to be used to export to the BGP peer (generated by the static protocol) stay in `t_r10`.

Don't worry if the whole construction with tables, protocols and pipes is still a bit confusing. First goal is to see the BGP routing in action, and afterwards I'll explain more about those BIRD internals.

Also, remember that the internal BIRD routing tables are not used to actually do packet forwarding. During the OSPF tutorial, we already discussed this difference between the "Control Plane" and "Forwarding Plane". Actually, the routing table inside the control plane is usually called the "RIB" (Routing Information Base), while the routing table that is used in the forwarding plane is called the "FIB" (Forwarding Information Base). Just look up all those terms on the internet to see what everyone is saying about them.

### Seeing it in action!

After adding the configuration on `R3`, fire up the interactive BIRD console, using `birdc`:

    root@R3:/# birdc 
    BIRD 1.4.5 ready.
    bird> 

Don't forget to tell BIRD to read and apply the changed configuration:

    bird> con
    Reading configuration from /etc/bird/bird.conf
    Reconfigured

Now, the three new protocols should be shown:

    bird> show protocols 
    name     proto    table    state  since       info
    kernel1  Kernel   master   up     2015-06-14  
    device1  Device   master   up     2015-06-14  
    ospf1    OSPF     master   up     2015-06-14  Running
    originate_to_r10 Static   t_r10    up     23:54:16    
    p_master_to_r10 Pipe     master   up     23:54:16    => t_r10
    ebgp_r10 BGP      t_r10    start  00:34:16    Active        Socket: Connection refused
    
    bird> show route table t_r10
    10.40.216.0/21     blackhole [originate_to_r10 23:54:16] * (200)
    10.40.0.0/22       blackhole [originate_to_r10 23:54:16] * (200)

Well, the routes are waiting to be pushed to `R10` in the `t_r10` table, and no routes from `AS65033` are visible yet. There's only an ugly "Connection refused"... reminding you that the other end of the BGP connection needs to be configured. Now it's up to you to configure `R10` with the opposite part of the configuration, and make it talk to `R3`!

When successful, the output of the commands above should show the BGP session to R3 as Established now:

    bird> show protocols 
    name     proto    table    state  since       info
    kernel1  Kernel   master   up     2015-06-14  
    device1  Device   master   up     2015-06-14  
    ospf1    OSPF     master   up     2015-06-14  Running
    originate_to_r3 Static   t_r3     up     00:48:27    
    ebgp_r3  BGP      t_r3     up     00:48:32    Established   
    p_master_to_r3 Pipe     master   up     00:48:27    => t_r3

Table `t_r3` now also contains the routes that are learned from `AS64080`:

    bird> show route table t_r3
    10.40.216.0/21     via 10.40.217.17 on vlan217 [ebgp_r3 00:48:32] * (100) [AS64080i]
    10.40.32.0/19      blackhole [originate_to_r3 00:48:27] * (200)
    10.40.0.0/22       via 10.40.217.17 on vlan217 [ebgp_r3 00:48:32] * (100) [AS64080i]

The above shows for example that prefix `10.40.216.0/21` was learned via the protocol `ebgp_r3`, at 00:48 AM, and that the range is originating from `AS64080`. The `via 10.40.217.17` is the BGP next-hop, which is the first router _outside_ our own network.

The BIRD master routing table also contains the routes learned over BGP, thanks to the `p_master_to_r3` protocol:

    bird> show route 
    10.40.217.16/30    dev vlan217 [ospf1 2015-06-14] * I (150/10) [10.40.32.10]
    10.40.216.0/21     via 10.40.217.17 on vlan217 [ebgp_r3 00:48:32] * (100) [AS64080i]
    10.40.33.0/26      dev vlan33 [ospf1 2015-06-14] * I (150/10) [10.40.32.12]
    10.40.36.0/24      via 10.40.33.3 on vlan33 [ospf1 2015-06-14] * I (150/20) [10.40.32.12]
    10.40.48.0/21      via 10.40.33.2 on vlan33 [ospf1 2015-06-14] * I (150/20) [10.40.32.11]
    10.40.32.10/32     dev lo [ospf1 2015-06-14] * I (150/0) [10.40.32.10]
    10.40.32.11/32     via 10.40.33.2 on vlan33 [ospf1 2015-06-14] * I (150/10) [10.40.32.11]
    10.40.0.0/22       via 10.40.217.17 on vlan217 [ebgp_r3 00:48:32] * (100) [AS64080i]
    10.40.32.12/32     via 10.40.33.3 on vlan33 [ospf1 2015-06-14] * I (150/10) [10.40.32.12]

The last step to get the routes into the actual forwarding table inside the Linux kernel is done by the kernel protocol. Since there is no explicit name given for the kernel protocol in the configuration, BIRD just names it `kernel1`.

    bird> show route export kernel1
    10.40.216.0/21     via 10.40.217.17 on vlan217 [ebgp_r3 00:48:32] * (100) [AS64080i]
    10.40.36.0/24      via 10.40.33.3 on vlan33 [ospf1 2015-06-14] * I (150/20) [10.40.32.12]
    10.40.48.0/21      via 10.40.33.2 on vlan33 [ospf1 2015-06-14] * I (150/20) [10.40.32.11]
    10.40.32.11/32     via 10.40.33.2 on vlan33 [ospf1 2015-06-14] * I (150/10) [10.40.32.11]
    10.40.0.0/22       via 10.40.217.17 on vlan217 [ebgp_r3 00:48:32] * (100) [AS64080i]
    10.40.32.12/32     via 10.40.33.3 on vlan33 [ospf1 2015-06-14] * I (150/10) [10.40.32.12]

Now the routes show up in the output of `ip route`, labeled with proto bird:

    root@R10:/# ip r
    10.40.0.0/22 via 10.40.217.17 dev vlan217  proto bird 
    10.40.32.11 via 10.40.33.2 dev vlan33  proto bird 
    10.40.32.12 via 10.40.33.3 dev vlan33  proto bird 
    10.40.33.0/26 dev vlan33  proto kernel  scope link  src 10.40.33.1 
    10.40.36.0/24 via 10.40.33.3 dev vlan33  proto bird 
    10.40.48.0/21 via 10.40.33.2 dev vlan33  proto bird 
    10.40.216.0/21 via 10.40.217.17 dev vlan217  proto bird 
    10.40.217.16/30 dev vlan217  proto kernel  scope link  src 10.40.217.18 

Well, let's have a look what we can do with this result. Since both networks are now aware of each other's routes, I'd expect I can do some tracerouting into a remote network now!

    root@R10:/# traceroute -n 10.40.2.6
    traceroute to 10.40.2.6 (10.40.2.6), 30 hops max, 60 byte packets
     1  10.40.217.17  0.356 ms  0.319 ms  0.324 ms
     2  10.40.216.2  0.430 ms  0.427 ms  0.378 ms
     3  10.40.2.6  0.781 ms  0.724 ms  0.716 ms

`R10` now knows the route to IPv4 ranges used in `AS64080`, and it seems `H6` also knows a route back to `R10`.

Let's try it from `H34`!

    root@H34:/# traceroute -n 10.40.2.6
    traceroute to 10.40.2.6 (10.40.2.6), 30 hops max, 60 byte packets
     1  10.40.36.1  0.296 ms !N  0.091 ms !N *

Meh, that doesn't look to good. Apparently there's more work to do.

### Some assignments

Now make sure you can do the following, and answer the following questions:

 * Configure the IPv6 BGP connection between `R3` and `R10`. IPv4 and IPv6 is handled separately by BIRD now, but the configuration for IPv6 is very similar to the configuration I showed here. Just use import all for bgp if you don't want to learn more about filtering now.
 * Explain why `10.40.217.18` or `2001:db8:40:d910::2` on `R10` can be pinged from `R1` now, while this was not the case before:

        root@R1:/# ping6 2001:db8:40:d910::2
        PING 2001:db8:40:d910::2(2001:db8:40:d910::2) 56 data bytes
        64 bytes from 2001:db8:40:d910::2: icmp_seq=1 ttl=63 time=0.399 ms
        64 bytes from 2001:db8:40:d910::2: icmp_seq=2 ttl=63 time=0.099 ms
        ^C
        --- 2001:db8:40:d910::2 ping statistics ---
        2 packets transmitted, 2 received, 0% packet loss, time 1000ms
        rtt min/avg/max/mdev = 0.099/0.249/0.399/0.150 ms

 * Try to export a route outside of `10.0.0.0/8` over BGP, from `R3` to `R10` and notice that the filter will actually stop that route from being propagated, while accepting the other routes. Using the `show route filtered protocol ebgp_r3` command the route should be visible, thanks to the `import keep filtered on` option that is set.
 * Figure out why, despite the fact that the two networks learned each others prefixes, you still cannot reach any router or host in the neighbor network that lies behing the border router. Try the following ICMP echo commands and explain why they do or don't succeed. Hint: use `tcpdump -ni vlanXYZ` on the right vlan interface to see the actual traffic, with source and destination addresses.
   - `R3` -> `R10`: `root@R3:/# ping 10.40.32.10`
   - `R3` -> `R11`: `root@R3:/# ping 10.40.32.11`
   - `R11` -> `R3`: `root@R11:/# ping 10.40.217.3`
   - `H12` -> `R1`: `root@R12:/# ping 10.40.217.1`

After explaining a bit more about the BIRD tables and protocols, we'll fix all these reachability issues.

## Intermezzo: BIRD tables, protocols, import, export

The usage of import, export, different protocols and routing tables can be a bit confusing at first. Well, at least [it was very frustrating for me](http://bird.network.cz/pipermail/bird-users/2013-January/008071.html), until [I found out](http://bird.network.cz/pipermail/bird-users/2013-January/008081.html) how to use it.

The main gotcha here is that the import and export statements are to be considered from the point of view of the BIRD routing table that is connected to the protocol (either by specifying the table option, or omitting it, using the default `master` table).

What I found out is that the easiest way to prevent confusion is to take the BIRD 'master' table as central point of reasoning, and then configure everything so that 'import' points closer to the master table, importing routes closer to the heart of BIRD, and 'export' points away from it, pushing routes to the outside world.

Here's a diagram of the BIRD configuration that we just used:

![BIRD protocols, tables, import and export](/bgp-intro/bird-prototable.png)

And here's how you should read the configuration that is in your routers right now:
 * table `master` is the central routing table of BIRD
 * kernel protocol `kernel1` exports routes from BIRD to Linux
 * ospf protocol `ospf1` imports routes from other OSPF routers in the network into BIRD
 * pipe protocol `p_master_to_r10` imports routes from its peer table `t_r10` into table `master`
 * table `t_r10` is another BIRD table that contains a collection of routes with attributes
 * static protocol `originate_to_r10` imports static routes into table `t_r10`
 * bgp protocol `ebgp_r10` exports routes from table `t_r10` to `R10`

Note that the OSPF protocol itself also generates routes for connected subnets that are stub or non-stub networks. These routes are not imported via the kernel protocol.

The output of `show protocols` should also totally make sense now (table column width adjusted):

    root@R3:/# birdc show protocols
    BIRD 1.4.5 ready.
    name              proto    table    state  since       info
    kernel1           Kernel   master   up     2015-06-14  
    device1           Device   master   up     2015-06-14  
    ospf1             OSPF     master   up     2015-06-14  Running
    originate_to_r10  Static   t_r10    up     2015-06-18  
    p_master_to_r10   Pipe     master   up     2015-06-18  => t_r10
    ebgp_r10          BGP      t_r10    up     2015-06-19  Established

Assignments:
 * The OSPF protocol configuration that we are using does not contain any table, import or export. This means it's using the defaults, which are table master, import all, export none. Add a line specifying `import none;` to the OSPF protocol configuration, and look at the effect on the BIRD master table, and the Linux routing table.
 * Change the BIRD configuration to use only the `master` table, eliminating the extra `t_r10` routing table, without changing the set of routes that are actually exported to the Linux kernel. Doing so should show that it's entirely possible, but that decreasing complexity by removing the extra table will increase complexity in the filters needed.

## Connecting the internal network

There's a last task that needs to be completed before every host and router in the two networks can see each other. As you just found out, only the border routers that actually speak BGP have learned the routes to the other network, and the internal routers still have no idea about them.

So, how should `R0` and `R1` be told about the routes from `AS65033` that are already known to `R3`?

### iBGP

BGP is not only meant to be used to connect to a router in an external network, it can also be used to connect back to routers in our own AS, to provide them with the learned information about externally reachable networks. A connection to a router in a different AS is called an eBGP connection, and, a connection to a router inside the same AS is called an iBGP connection.

In the inside network, iBGP can run alongside OSPF on the routers, the difference between them being that OSPF carries the internal routes, and BGP the external ones:

 * OSPF, the IGP, contains all information about routes _inside_ our network.
 * BGP, the EGP, contains all information about _external_ connectivity.

![OSPF, eBGP and iBGP](/bgp-intro/ospf-ebgp-ibgp.png)

### BIRD iBGP configuration

Here's an example for the IPv6 iBGP connection between `R3` and `R1`:

In the IPv6 BIRD configuration of `R3`, add:

    protocol bgp ibgp_r1 {
        import none;
        export where source = RTS_BGP;
        local    2001:db8:40::3 as 64080;
        neighbor 2001:db8:40::1 as 64080;
    }

In the IPv6 BIRD configuration of `R1`, add:

    protocol bgp ibgp_r3 {
        local    2001:db8:40::1 as 64080;
        neighbor 2001:db8:40::3 as 64080;
    }

Using the same AS number for the local and neighbor address simply tells BIRD that we're dealing with an iBGP connection.

Do a `birdc6 configure` in `R1` and `R3`, and look at the result on `R1`:

    root@R1:/# birdc6 show route protocol ibgp_r3
    BIRD 1.4.5 ready.
    2001:db8:10::/48   via fe80::aff:fe28:d801 on vlan216 [ibgp_r3 23:26:12 from 2001:db8:40::3] * (100/20) [AS65033i]

BIRD just learned a route to the remote AS! And, because of this, `H7` in `AS64080` and `R10` in `AS65033` can now find each other:

    root@H7:/# traceroute6 -n 2001:db8:10:6::a
    traceroute to 2001:db8:10:6::a (2001:db8:10:6::a), 30 hops max, 80 byte packets
     1  2001:db8:40:3::1  0.556 ms  0.501 ms  0.501 ms
     2  2001:db8:40:d8::1  1.059 ms  1.074 ms  1.078 ms
     3  2001:db8:10:6::a  1.281 ms  1.274 ms  1.268 ms

### How OSPF and BGP work together

Since BGP only handles external connectivity, the protocol does not try to be clever about routes inside the local network. When taking a closer look at the BGP route that is received by `R1`, it shows that the BGP information attached to the route only contains information about the first hop _outside_ the network, which is called the BGP next hop:

    root@R1:/# birdc6
    BIRD 1.4.5 ready.
    bird> show route all 2001:db8:10::/48
    2001:db8:10::/48   via fe80::aff:fe28:d801 on vlan216 [ibgp_r3 23:26:11 from 2001:db8:40::3] * (100/20) [AS65033i]
        Type: BGP unicast univ
        BGP.origin: IGP
        BGP.as_path: 65033
        BGP.next_hop: 2001:db8:40:d910::2
        BGP.local_pref: 100

Since `R1` has only got this information, BIRD has to find out what the actual next hop to a router in a directly connected subnet has to be before a route can be exported to the Linux kernel. Luckily this is where the cooperation of the IGP comes into play. Since OSPF knows a route to `2001:db8:40:d910::2`, it can tell us where to forward the traffic in the local network to push it closer to that external BGP next hop. This is exactly the reason why the subnets that connect to routers just outside our own network are also included in OSPF as stub networks!

    bird> show route for 2001:db8:40:d910::2
    2001:db8:40:d910::/120 via fe80::aff:fe28:d801 on vlan216 [ospf1 2015-06-14] * I (150/20) [10.40.217.3]

Remember the section about next-hops in the OSPF tutorial? If not, go back and re-read it ("Step three: figuring out shortest paths and determining next-hops"). The same logic applies here. While this router already has a strong opinion about the path that traffic to `2001:db8:10:6::a` has to take to reach the remote network, all this knowledge gets thrown away even before the actual IP packet leaves this router... While BIRD knows the entry point in the remote network, as well as the path through the internal network to reach it, it can only install a route to the locally connected next hop into the actual forwarding routing table of the Linux kernel. The next router which receives the packet has to apply all routing logic again itself to get it forwarded into the right direction. Luckily, protocols like OSPF and BGP are designed in a way that enables us to trust that all routers that cooperate in the routing protocols have the same mindset and will perfectly work together to get the traffic to its destination without endlessly forwarding it in loops between them.

The only thing that the routers in`AS64080` know is that `R10` is the entry point for `AS65033`, and how to get there. They do not have the slightest knowledge about how the internal network of `AS65033` is organized, and there is no way for them to learn about this. When the traffic enters the remote network, that network will take care of delivering it to the actual router or host in that network.

### Can OSPF be used instead of iBGP?

After getting to know iBGP, you might still wonder: "If the routes are in the BIRD master table, and we already have the routers inside the AS talking to each other, why not just export the BGP routes into OSPF?". Well, actually, that can be done, and we can try it for fun. In order to redistribute the BGP routes into OSPF, just shut down the iBGP connections again and add the line `export where source = RTS_BGP;` to the OSPF section of both `R3` and `R10` and `birdc configure`.

For example, `R11` now shows:

    root@R11:/# birdc6 show r
    BIRD 1.4.5 ready.
    2001:db8:10:24::/120 via fe80::aff:fe28:2103 on vlan33 [ospf1 2015-06-14] * I (150/20) [10.40.32.12]
    2001:db8:10:21::/120 dev vlan33 [ospf1 2015-06-14] * I (150/10) [10.40.32.12]
    2001:db8:10:30::/117 dev vlan48 [ospf1 2015-06-14] * I (150/10) [10.40.32.11]
    2001:db8:10:6::a/128 via fe80::aff:fe28:2101 on vlan33 [ospf1 2015-06-14] * I (150/20) [10.40.32.10]
    2001:db8:10:6::c/128 via fe80::aff:fe28:2103 on vlan33 [ospf1 2015-06-14] * I (150/20) [10.40.32.12]
    2001:db8:40::/48   via fe80::aff:fe28:2101 on vlan33 [ospf1 21:00:55] * E2 (150/20/10000) [10.40.32.10]
    2001:db8:40:d910::/120 via fe80::aff:fe28:2101 on vlan33 [ospf1 2015-06-14] * I (150/20) [10.40.32.10]

You can see that the route to the neighbor AS is present, but it's tagged as an 'E2' route in OSPF, instead of the usual 'I', meaning it was imported from a different routing protocol on the router that originates this prefix, `10.40.32.10`.

While using OSPF to transport the routes to the other internal routes might work in our little example network in this tutorial, it introduces a number of limitations, one of them being that all extra BGP specific information attached to a route is lost when converting it from a BGP to an OSPF route. This limits the amount of control that can be exercised on the selection of the exit point for traffic from a network to external networks. Another reason to refrain from doing this is that the full BGP table of the Internet contains more than half a million network prefixes. So if you would run a router in a location where you have all those routes in a BGP table, redistributing them to OSPF, pretending that the entire Internet is part of your local network will probably blow up your OSPF process. It's not designed to handle that. ;-)

### The usage of loopback addresses

It might have occurred to you that the iBGP BIRD configuration specifies the local and remote address using loopback addresses instead of interface addresses from an actual connected subnet. Think back of the "The loopback address" section of the OSPF tutorial! The BGP router on the edge of the network, and the internal router which wants to learn about external connectivity using iBGP can be anywhere in the internal network. There may even exist multiple possible paths between them. By using a loopback address as source and target of the iBGP connection, the connection will keep functioning as long as there is any possible path between the two routers. The flow of traffic to the external network will follow the same directions as the iBGP control connection, since both of them use the IGP to reach each other.

![iBGP relying on the IGP](/bgp-intro/ibgp-loopback.png)

### Final assignments:

 * Well, this one is obvious... Practice some more by finishing setting up all connectivity by configuring the iBGP sessions for IPv4 and IPv6 between `R0` and `R3`, between `R10` and `R11`, and between `R10` and `R12`. Confirm by tracerouting from `H34` and `H19` in `AS65033` to `H6` and `H7` in `AS64080`.
 * If there's any part of the this first BGP tutorial that you do not understand already, make sure you will. The following tutorials will be building upon the knowledge gathered here. Don't get depressed if you don't get all of it the first time. Just go back to the top and read the page again, there's an awful lot of information compacted in this page. If you're brave, make up your own example network and try to build it from scratch. It will take some time, but as soon as you are able to traceroute from one far end to another, you've likely run into and solved all aspects you missed before.
 * Look around on the internet and read other blogs and tutorials about OSPF and BGP and see if they're much more easy to understand having a frame of reference which was set by following this tutorial.

In the next tutorial, [BGP Part II](/bgp-contd/README.md), I'll show more interesting topologies of different networks connecting together using BGP than just two networks with one eBGP connection. By doing so, we'll quickly discover and understand how the actual huge Internet is organized.
