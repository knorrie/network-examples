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

Our networks start to look serious now! Thankfully, most of the configuration is provided already, so we can quickly set up this whole network using our LXC environment. Just like in the previous tutorial, the birdbase container can be cloned, after which the lxc network information and configuration inside the containers can be copied into them.

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

 3. Set up the network interfaces in the lxc configuration. This can be done by removing all network related configuration that remains from the cloned birdbase container, and then appending all needed interface configuration by running the fixnetwork.sh script that can be found in `bgp-intro/lxc/` in this git repository. Of course, have a look at the contents of the script first, before executing it. Since this example is only using IPv4 and single IP addresses on the interfaces, I simply added them to the lxc configuration instead of the network/interfaces file inside the container.

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

Remember, the internal BIRD routing tables are not used to actually do packet forwarding. During the OSPF tutorial, we already discussed this difference between the "Control Plane" and "Forwarding Plane". Actually, the routing table inside the control plane is usually called the "RIB" (Routing Information Base), while the routing table that is used in the forwarding plane is called the "FIB" (Forwarding Information Base). Just look up all those terms on the internet to see what everyone is saying about them.

### Seeing it in action!

After adding the configuration, fire up the interactive BIRD console, using `birdc`:

    root@R3:/# birdc 
    BIRD 1.4.5 ready.
    
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

When successful, the output of the commands above should show, on `R10`:

    bird> show protocols 
    name     proto    table    state  since       info
    kernel1  Kernel   master   up     2015-06-14  
    device1  Device   master   up     2015-06-14  
    ospf1    OSPF     master   up     2015-06-14  Running
    originate_to_r3 Static   t_r3     up     00:48:27    
    ebgp_r3  BGP      t_r3     up     00:48:32    Established   
    p_master_to_r3 Pipe     master   up     00:48:27    => t_r3
    
    bird> show route table t_r3
    10.40.216.0/21     via 10.40.217.17 on vlan217 [ebgp_r3 00:48:32] * (100) [AS64080i]
    10.40.32.0/19      blackhole [originate_to_r3 00:48:27] * (200)
    10.40.0.0/22       via 10.40.217.17 on vlan217 [ebgp_r3 00:48:32] * (100) [AS64080i]
    
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

    bird> show route export kernel1
    10.40.216.0/21     via 10.40.217.17 on vlan217 [ebgp_r3 00:48:32] * (100) [AS64080i]
    10.40.36.0/24      via 10.40.33.3 on vlan33 [ospf1 2015-06-14] * I (150/20) [10.40.32.12]
    10.40.48.0/21      via 10.40.33.2 on vlan33 [ospf1 2015-06-14] * I (150/20) [10.40.32.11]
    10.40.32.11/32     via 10.40.33.2 on vlan33 [ospf1 2015-06-14] * I (150/10) [10.40.32.11]
    10.40.0.0/22       via 10.40.217.17 on vlan217 [ebgp_r3 00:48:32] * (100) [AS64080i]
    10.40.32.12/32     via 10.40.33.3 on vlan33 [ospf1 2015-06-14] * I (150/10) [10.40.32.12]

Since there is no explicit name given for the kernel protocol in the configuration, BIRD just names it `kernel1`. As you can see, the table `t_r3` contains the static routes which are exported via BGP to `R3`, and it also contains two routes that were learned from `R3`. Yay! The default `show route` command shows routes that are in the BIRD master table. You can see that the `p_master_to_r3` pipe protocol correctly copied the routes that were learned from `R3` from table `t_r3` to the `master` table. The kernel protocol then exports all dynamically learned routes to the actual forwarding table in the Linux kernel, where they show up as output of `ip route`, labeled with proto bird:

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

------------

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
