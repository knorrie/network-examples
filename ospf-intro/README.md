OSPF
====

In this tutorial, I'll explain a bit about how the OSPF routing protocol works, followed by a full hands-on tutorial to practice and see it in action yourself!

In the [previous page of this tutorial series](/birdhouse-vlans-vpn/README.md), we met the Birdhouse Factory sysadmin Carl, who was about to get a little depressed about the amount of manual work he needed to do to get his newly created set of routers forward traffic into the right direction. He wondered if there would be a better way to do this, having the routers just tell each other what traffic should go where.

Luckily, such a thing actually exists. Instead of programming all routers in detail with the next hop for each possible subnet that exists in the network, it's possible to let the routers figure this out themselves.

## Step one: separate routers with interfaces

The network in this tutorial has four routers. Each of these routers has connections to multiple networks:

![OSPF network, separate](/ospf-intro/ospf-separate.png)

Each of the four routers is shown as a little "card" with information on it, which contains:

 * A unique IP address-like number (in bold), which is a so called 'Router ID'.
 * Several interfaces, which are connected to different subnets, having a unique address in each of those subnets.
 * A "stub" sign that is either missing or present on the interface.

If the network is a "stub", it's like a dead end road, and we expect that the network contains end hosts (like servers and workstations), but no other routers. If the network is not a stub, we consider it a network where other routers are present, and usually no end hosts.

So what's different between the network drawings of the Birdhouse Factory that we've seen in the previous tutorials? On the last page, we learned that sysadmin Carl had designed the whole network on paper first, and then had to program all routes to other networks into each router in the network. The image above looks like the complete opposite. We have four routers, and each of them only knows about its directly connected subnets, and has no idea at all about the existence of the other three routers. This seems strange, but it's an ideal starting point for a dynamic routing protocol like OSPF. The topology of an OSPF network is not laid out in advance. The network completely discovers itself "on the go".

## Step two: activating OSPF, discovering network topology

When looking at the picture with the four separate routers, you should already have noticed that some of the interfaces of different routers share the same subnet. For example, `10.0.1.5` of R1 and `10.0.1.4` of R5 are in the same subnet, and connected to the same vlan. This means they should be able to communicate with each other. Only, they don't know about each other yet.

*Warning: the following is a grossly oversimplified description of the OSPF discovery process, but just enough to grasp the basics that we need to know before trying it.*

### Discovering local neighbours

To discover which routers can directly see each other, the following is being done by them:

 * Send out Hello! packets, describing themselves (containing, most importantly, their Router ID) on all interfaces that actively participate in the OSPF network (so all non-stub interfaces).
 * Listen for Hello! packets from other routers, to learn who else is active out there.

![OSPF network with discovered neighbours](/ospf-intro/ospf-neighbours.png)

Now, the upper part of the network contains three routers which know they are neighbours, as does the lower part. But, router 2 and 6 do not know about each other's existence yet.

### Discovering the full network topology

To discover the full topology of the network, the following happens:
 * Send out the complete information card of the router itself, with all information of active "links" that the router has to all neighbours.
 * Receive the same information from neighbour routers.
 * When an information card of a router arrives, store it, and send it out again on all other interfaces that are not a stub, unless the information of this particular router was already received before.

And magically... After a short burst of network traffic, all routers have now received each other's information, and are in possession of the four cards with information. Now that each router has all information about the other ones, let's see what happens when we simply connect the information about the four different routers together, turning the shared subnet ranges into a subnet between the routers:

![OSPF network, joined together](/ospf-intro/ospf-together.png)

And now here's a very important characteristic of the OSPF protocol: *Each* of the four routers can do this, and each of them now has an overview of the complete topology of the network! And, all of them have the *exact* same one.

## Step three: figuring out shortest paths and determining next-hops

Now that each router has gathered enough information to assemble a complete detailed map of the complete network, the meaning of the abbreviation OSPF comes into play. OSPF means "Open Shortest Path First". Using the details of the network topology map, it's possible to find out the shortest path to every subnet that exists in the network (being stub or not). If you want to know how this is done, look up the Dijkstra's algorithm, which is the mathematical algorithm that is used by OSPF.

While each router can determine the complete shortest path to any destination in the network, it might sound quite disappointing to know that most of this valuable information can not be used by any individual router to get an IP packet to its destination.

 * First of all, the routing software (for which BIRD will be used in these tutorials) is not in charge of the forwarding of packets itself (which is done by the Linux kernel in these examples). This difference is well known as the difference between a "Control Plane" and a "Forwarding Plane", which have nothing to do with aircrafts.
 * The routing software (control plane) has to program the kernel (forwarding plane) with a next hop router for each existing subnet in the network, and it can not provide more information than just that next hop, which has to be in a directly connected subnet. So the OSPF routing process knows much more about the path that the to be forwarded packet will travel than it is able to tell the forwarding path.

And why shouldn't we care too much about all of this? The fun part here is that each of the participating routers in the OSPF network knows exactly the same amount of information about the whole network topology, and uses the same way to calculate the shortest routes from itself to all subnets that exist in the network. So, it's not a problem at all that the OSPF process on R2 can only tell the linux kernel to forward packets for `10.34.2.89` to a next hop of `10.1.2.56`, because it can trust on the fact that R5 will always forward them again to `10.0.1.8`, having R6 receive them, which will drop them into the connected subnet to reach the end host in there.

If you're confused now, don't worry. Take a short break and continue with the hands-on part to see it all happen! After doing so, re-read the above, which should probably make more sense then.

If you're not confused yet, here's some bonus information to think about: To make it even worse, the IP address of this next hop is not even used when actually forwarding a packet to the next router! It's only being used to determine the layer 2 mac address of the interface of the next hop. :-) An IP packet contains a source and a destination IP address. It does not contain a list of routers that it needs to pass before reaching its destination. It does not even contain the address of the very first next hop that it needs to go to, and the receiving next router has no idea where the packet it just received has been, or which IP address was used to forward it. It only sees the mac address of the sending router.

# Hands on!

Enough of this theoretical babble! Let's create the network ourselves, using some linux containers and vlans with openvswitch!

Ok, first of all, to be honest, the stub links still look a bit sad, so let's connect a host to them, which we will use later, when we'll actually building the network, to execute tests between them to see if they can reach each other, and if so, using what route over the network:

![OSPF network, joined together with some hosts](/ospf-intro/ospf-together-hosts.png)

## Building the containers

Let's build some containers! If you don't have [a lab environment](/lxcbird/README.md) with a template 'birdbase' container yet, create it!

To create the eight containers we need, connected together in different networks, the following steps are needed:

 1. Clone this git repository somewhere to be able to use some files from the ospf-intro/lxc/ directory inside.
 2. lxc-copy the birdbase container several times:

        lxc-copy -s -n birdbase -N R1
        lxc-copy -s -n birdbase -N R2
        lxc-copy -s -n birdbase -N R5
        lxc-copy -s -n birdbase -N R6
        lxc-copy -s -n birdbase -N H12
        lxc-copy -s -n birdbase -N H10
        lxc-copy -s -n birdbase -N H8
        lxc-copy -s -n birdbase -N H5

 3. Set up the network interfaces in the lxc configuration. This can be done by removing all network related configuration that remains from the cloned birdbase container, and then appending all needed interface configuration by running the fixnetwork.sh script that can be found in `ospf-intro/lxc/` in this git repository. Of course, have a look at the contents of the script first, before executing it. Since this example is only using IPv4 and single IP addresses on the interfaces, I simply added them to the lxc configuration instead of the network/interfaces file inside the container.

        . ./fixnetwork.sh

 4. Copy extra configuration into the containers. The ospf-intro/lxc/ directory inside this git repository contains a little file hierarchy that can just be copied over the configuration of the containers. For each router, it's a network/interfaces configuration file which adds an IP address that corresponds with the Router ID to the loopback interface, and a simple BIRD configuration file that serves as a starting point for our next steps.

 5. Start all containers

        for router in 1 2 5 6; do lxc-start -d -n R$router; sleep 2; done
		for host in 12 10 8 5; do lxc-start -d -n H$host; sleep 2; done

 6. Verify connectivity and look around a bit. Here's an example for R1:

        lxc-attach -n R1
        
        root@R1:/# 
        root@R1:/# ip a
        1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default 
            link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
            inet 127.0.0.1/8 scope host lo
               valid_lft forever preferred_lft forever
            inet 10.9.99.1/32 scope global lo
               valid_lft forever preferred_lft forever
            inet6 ::1/128 scope host 
               valid_lft forever preferred_lft forever
        247: vlan1001: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
            link/ether 02:00:0a:00:01:05 brd ff:ff:ff:ff:ff:ff
            inet 10.0.1.5/24 brd 10.0.1.255 scope global vlan1001
               valid_lft forever preferred_lft forever
            inet6 fe80::aff:fe00:105/64 scope link 
               valid_lft forever preferred_lft forever
        249: vlan1012: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
            link/ether 02:00:0a:01:02:07 brd ff:ff:ff:ff:ff:ff
            inet 10.1.2.7/24 brd 10.1.2.255 scope global vlan1012
               valid_lft forever preferred_lft forever
            inet6 fe80::aff:fe01:207/64 scope link 
               valid_lft forever preferred_lft forever
        251: vlan1356: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
            link/ether 02:00:0a:03:38:01 brd ff:ff:ff:ff:ff:ff
            inet 10.3.56.1/24 brd 10.3.56.255 scope global vlan1356
               valid_lft forever preferred_lft forever
            inet6 fe80::aff:fe03:3801/64 scope link 
               valid_lft forever preferred_lft forever
        
        root@R1:/# ip r
        10.0.1.0/24 dev vlan1001  proto kernel  scope link  src 10.0.1.5 
        10.1.2.0/24 dev vlan1012  proto kernel  scope link  src 10.1.2.7 
        10.3.56.0/24 dev vlan1356  proto kernel  scope link  src 10.3.56.1 
        
        root@R1:/# ping -c 3 10.3.56.8
        PING 10.3.56.8 (10.3.56.8) 56(84) bytes of data.
        64 bytes from 10.3.56.8: icmp_seq=1 ttl=64 time=0.545 ms
        64 bytes from 10.3.56.8: icmp_seq=2 ttl=64 time=0.084 ms
        64 bytes from 10.3.56.8: icmp_seq=3 ttl=64 time=0.078 ms
        
        --- 10.3.56.8 ping statistics ---
        3 packets transmitted, 3 received, 0% packet loss, time 1998ms
        rtt min/avg/max/mdev = 0.078/0.235/0.545/0.219 ms
        root@R1:/# 
        
        root@R1:/# traceroute 10.34.2.5
        traceroute to 10.34.2.5 (10.34.2.5), 30 hops max, 60 byte packets
        connect: Network is unreachable
    
Looking good! :-) Feel free to test some more and by attaching to the console of containers and playing around.

## Basic BIRD configuration

To be able to use the OSPF routing protocol, we need to run a program on each router that implements it. BIRD, the BIRD Internet Routing Daemon is one of those and I'll be using it for all examples and tutorials here.

Let's have a look at the BIRD configuration of R6:

    # cat R6/rootfs/etc/bird/bird.conf
    router id 10.9.99.6;

    log "/var/log/bird/bird.log" all;
    debug protocols { states, routes, filters, interfaces }
    
    protocol kernel {
            import none;
            export all;
    }
    
    protocol device {
            # defaults...
    }

This is a really basic BIRD configuration:

 * The Router ID is set to a unique value in the network, which is 10.9.99.6 for this router. Actually, this is not an IP address. It's just a 32 bit value, but it's written in the same notation we use for IPv4 address, instead of 0x0a096306 or 168387334.
 * A kernel protocol. This is not a real routing protocol, but it's the way BIRD uses to export route information from the internal BIRD routing table to the Linux kernel (remember, the control plane programs the forwarding plane). The filters are set to export all routes that BIRD will be learning from other routers to the Linux kernel routing table, which is fine for now.
 * A device protocol. This is also not a real routing protocol, but the way BIRD uses to import information about the local network interfaces that are already present in this routers. Usually this is added to your BIRD configuration and just sits there, doing its thing.

As you have seen above, all of the routers currently only see their connected subnets. R1 which was used as an example above has no idea how to reach a computer with IP address 10.34.2.5, because it has no available route to a network this address is in:

    root@R1:/# ip r
    10.0.1.0/24 dev vlan1001  proto kernel  scope link  src 10.0.1.5 
    10.1.2.0/24 dev vlan1012  proto kernel  scope link  src 10.1.2.7 
    10.3.56.0/24 dev vlan1356  proto kernel  scope link  src 10.3.56.1 

`ip r` shows the Linux kernel route table, which is used to actually forward packets. The BIRD process has its own internal routing table, which can also be shown:

    root@R1:/# birdc show route
    BIRD 1.4.5 ready.
    root@R1:/# 

Well, actually it's still empty now. :-)

birdc is a little program which connects to a running BIRD process for diagnostics and like manipulation of the running protocols, like disabling or enabling them:

    root@R1:/# birdc
    BIRD 1.4.5 ready.
    bird> show route
    bird> show ?
    show bfd ...                                   Show information about BFD protocol
    show interfaces                                Show network interfaces
    show memory                                    Show memory usage
    show ospf ...                                  Show information about OSPF protocol
    show protocols [<protocol> | "<pattern>"]      Show routing protocols
    show roa ...                                   Show ROA table
    show route ...                                 Show routing table
    show static [<name>]                           Show details of static protocol
    show status                                    Show router status
    show symbols ...                               Show all known symbolic names
    bird> show status
    BIRD 1.4.5
    Router ID is 10.9.99.1
    Current server time is 2015-06-07 00:51:52
    Last reboot on 2015-06-07 00:02:37
    Last reconfiguration on 2015-06-07 00:43:57
    Daemon is up and running
    bird> 
    bird> show protocols 
    name     proto    table    state  since       info
    kernel1  Kernel   master   up     00:02:37    
    device1  Device   master   up     00:02:37    

## Configuring OSPF

The moment we've all been waiting for! Add the following to bird.conf of R6. Editing the bird.conf file can be done from outside the container.

    protocol ospf {
            area 0 {
                    interface "lo" {
                            stub;
                    };
                    interface "vlan1001" {
                    };
                    interface "vlan1034" {
                            stub;
                    };
            };
    }

Now, tell BIRD to reload the configuration:

    root@R6:/# birdc
    BIRD 1.4.5 ready.
    bird> configure
    Reading configuration from /etc/bird/bird.conf
    Reconfigured

An OSPF protocol instance has been started now, which has been provided with information that closely relates to the little "router information cards" seen earlier:

![OSPF R6](/ospf-intro/ospf-r6.png)

The interface in network `10.0.1.0/24` has been configured as active OSPF interface. The interface in `10.34.2.0/24` is a stub, and also the Linux loopback interface has been specified as stub, causing the `10.9.99.6/32` address that is present on the loopback interface to be included in the OSPF process.

After starting OSPF, the Linux kernel routing table still looks unchanged, but the routing table inside BIRD has changed:

    root@R6:/# ip r
    10.0.1.0/24 dev vlan1001  proto kernel  scope link  src 10.0.1.8 
    10.34.2.0/24 dev vlan1034  proto kernel  scope link  src 10.34.2.1 
    
    root@R6:/# birdc show route
    BIRD 1.4.5 ready.
    10.0.1.0/24        dev vlan1001 [ospf1 00:58:01] * I (150/10) [10.9.99.6]
    10.9.99.6/32       dev lo [ospf1 00:58:01] * I (150/0) [10.9.99.6]
    10.34.2.0/24       dev vlan1034 [ospf1 00:58:01] * I (150/10) [10.9.99.6]

Since BIRD has been told which interfaces are participating in the OSPF protocol, it has been able to determine which network ranges are active on those interfaces. When talking to other OSPF routers, this is the information that will be sent to them in the R6 information message!

There are more useful commands to show what R6 is currently seeing in the OSPF network:

    bird> show ospf topology 
    
    area 0.0.0.0
    
    	router 10.9.99.6
    		distance 0
    bird> show ospf neighbors 
    ospf1:
    Router ID   	Pri	     State     	DTime	Interface  Router IP   

Only, the output is not very exciting, because apparently there are no other routers available yet which can answer the Hellos that R6 is sending onto vlan1001...

## A second OSPF router, or more!

The inevitable must happen. Right now, you should know enough to be able to configure OSPF on R1 as well, which has two active OSPF interfaces, the stub interface which connects to the network with H8, and of course the loopback interface.

Go ahead, do it, now!

After adding the configuration and making BIRD reload it, `birdc show protocols` should show an active OSPF protocol. Now, just wait for a few seconds and do `ip r` again on R6, which shows us the routing table that is actually used by the forwarding process:

    root@R6:/# ip r
    10.0.1.0/24 dev vlan1001  proto kernel  scope link  src 10.0.1.8 
    10.1.2.0/24 via 10.0.1.5 dev vlan1001  proto bird 
    10.3.56.0/24 via 10.0.1.5 dev vlan1001  proto bird 
    10.9.99.1 via 10.0.1.5 dev vlan1001  proto bird 
    10.34.2.0/24 dev vlan1034  proto kernel  scope link  src 10.34.2.1 

In the interactive BIRD console, `show route` can be used to see the view that BIRD has on the network. You can see that the three routes that have nexthop `10.0.1.5` were learned from router `10.9.99.1`, which is the Router ID of R1.

    bird> show route
    10.0.1.0/24        dev vlan1001 [ospf1 2015-06-07] * I (150/10) [10.9.99.6]
    10.1.2.0/24        via 10.0.1.5 on vlan1001 [ospf1 22:51:52] * I (150/20) [10.9.99.1]
    10.3.56.0/24       via 10.0.1.5 on vlan1001 [ospf1 2015-06-07] * I (150/20) [10.9.99.1]
    10.9.99.1/32       via 10.0.1.5 on vlan1001 [ospf1 2015-06-07] * I (150/10) [10.9.99.1]
    10.9.99.6/32       dev lo [ospf1 2015-06-07] * I (150/0) [10.9.99.6]
    10.34.2.0/24       dev vlan1034 [ospf1 2015-06-07] * I (150/10) [10.9.99.6]

I guess it's not very useful any more to continue typing much more text in this tutorial page now, because I'm quite surely losing your attention. :-D Just go ahead, and configure OSPF on the other two routers and see what happens. One fun thing to do is to start a `watch ip r` on R6 and see live changes of what will happen while you're working on the other routers.

When enabling OSPF on all four routers, you should be able to reach anything from anything in the whole network.

    root@H12:/# traceroute -n 10.34.2.5
    traceroute to 10.34.2.5 (10.34.2.5), 30 hops max, 60 byte packets
     1  10.50.1.1  0.199 ms  0.227 ms  0.119 ms
     2  10.1.2.56  0.238 ms  0.234 ms  0.284 ms
     3  10.0.1.8  0.283 ms  0.282 ms  0.332 ms
     4  10.34.2.5  0.310 ms  0.389 ms  0.246 ms

Or...

    root@H12:/# mtr -n -c 3 -r 10.3.56.8
    Start: Sun Jun  7 01:46:49 2015
    HOST: H12                         Loss%   Snt   Last   Avg  Best  Wrst StDev
      1.|-- 10.50.1.1                  0.0%     3    0.1   0.2   0.1   0.3   0.0
      2.|-- 10.1.2.7                   0.0%     3    0.1   0.2   0.1   0.3   0.0
      3.|-- 10.3.56.8                  0.0%     3    0.1   0.2   0.1   0.4   0.0

## More Dynamics!

There's two more topics I want to cover before ending this tutorial. The first one is how the network will handle changes in the availability of paths.

Attach to H12 and start an `mtr -n 10.34.2.5`. In my case here, it shows a path via `10.50.1.1` (R2), `10.1.2.56` (R5) and `10.0.1.8` (R6). Now, just for fun, do an `ip link set down vlan1012` on R5 if your traceroute shows the same path, or if the route is over R1, just down an interface on R1 instead, and look what's happening to your running mtr output. Doing this is equivalent to pulling a network cable out of a network port of a "real" router.

Here's mine:

                                 My traceroute  [v0.85]
    H12 (0.0.0.0)                                          Sun Jun  7 01:56:35 2015
    Keys:  Help   Display mode   Restart statistics   Order of fields   quit
                                           Packets               Pings
     Host                                Loss%   Snt   Last   Avg  Best  Wrst StDev
     1. 10.50.1.1                         0.0%   230    0.1   0.1   0.1   0.4   0.0
     2. 10.1.2.56                         0.9%   230    0.1   0.1   0.1   0.3   0.0
        10.1.2.7
     3. 10.0.1.8                          0.9%   230    0.1   0.1   0.1   0.4   0.0
     4. 10.34.2.5                         0.9%   230    0.1   0.1   0.1   0.4   0.0

![OSPF network, reconvergence](/ospf-intro/ospf-together-hosts-linkdown.png)

When I disabled the interface on R5, BIRD on R5 got notified by netlink that the interface went down. OSPF on R5 had to change its information card immediately and send it out again. But... it was only able to send it out on the `10.0.1.0/24` network. So it did, and R1 and R6 received it. Since R1 had not seen an update on the lower side of the network, it notified routers in there of the change and R2 was able to recalculate the shortest paths to the entire network after changing its view of the complete network topology with the missing link between R5 and the `10.1.2.0/24` network. After doing so, R2 determined that the current open shortest path to `10.34.2.5` had to be via `10.1.2.7` and used the BIRD kernel protocol to retract the route to `10.34.2.0/24` via `10.1.2.56` and inserted a new route into the Linux kernel routing table which points to `10.1.2.7` as next hop for `10.34.2.0/24`. And then, mtr noticed there was a change in the path.

Apparently, I lost a ping while the network was busy to get into a stable converged state again. ;-(

## The loopback address

The second thing I want to point out is about the /32 addresses on the loopback interfaces of the routers. I figure you might be wondering what they're useful for. Well, normally, a /32 address on a network interface would not make much sense. But image what happens when we include it in our OSPF process... It suddenly becomes a network subnet whose reachability information is propagated throughout the whole network. Ok, this subnet can only contain a single address, but it's a perfect way to make sure that if any path exists to this single router in the network, OSPF will make you able to use it to connect to the router. So, if I'm the network administrator of the example network we've just built, and `10.50.1.12` is my workstation, I can use `10.9.9.5` to connect to, for example with SSH, to manage this router. Even when I accidentally would disable the link to the `10.1.2.0/24` network, my SSH session would simply stay active, the traffic to and from R5 being rerouted via R1 back to my workstation... :-D Later on, in the BGP tutorial we'll see that there are actually other routing protocols that rely on this mechanism to function correctly.

## Next...

There are numerous pages with information about OSPF on the internet. Since I couldn't really find one of them that did not directly deep-dive into 100s of pages of concepts like different type of LSAs, DR, BDR, Areas, and a lot of other complex things instead of just showing that a bunch of routers can talk to each other, I created this tutorial to prove routing protocols are fun, and to encourage you to have fun building networks. :-)

First of all, don't forget to take a look at the BIRD documentation about OSPF. You can find it at User's guide -> Protocols -> OSPF at the [BIRD web page](http://bird.network.cz/). There's a lot more options than "stub". :) While I just proved you don't need to know about them to set up an interesting network with dynamic routing, there must be scenarios in which they can be very useful. For example:
 * If there are untrusted hosts inside your routing vlans, you might want to use password authentication.
 * If you want to decrease the time until the network gets reconfigured when a router crashes without notifying anyone, you might want to play with hello timers, or even bfd.
 * Equal cost multipath routing (ECMP) is a big thing nowadays, which is used a lot to load balance traffic over multiple paths to a destination instead of choosing only one as best path. You can even enable that in the network we just built by just specifying `ecmp yes` in the OSPF configuration (try it on R2 or R6) and see what effect it has on the output of `ip r` on the linux command line. Just search for information on it on the Internet to learn more.
 * 'Cost' is an aspect that is fundamental to OSPF and the calculation of the shortest paths in the network. Traditionally, cost is related to the bandwidth of a link between routers, and causes higher bandwidth connections to be prefered above lower bandwidth connections. Since we're working with switched Gigabit/s networks by default now, if it's not 10Gb/s, in the datacenter and even in our office, I've just been ignoring that.

Another thing you can play with is rolling out IPv6 on this little network that was just built. It needs a `bird6.conf` configuration file, and you'll soon find out doing IPv6 is very similar to what we did here with IPv4. Just pick some subnets from the `2001:db8::/32` network to work with and there you go.

After completing this tutorial, I also encourage you to start reading the other "An Introduction to OSPF" like pages on the internet, since they should be a lot easier to understand while having seen it work for real! Have fun.

Next: [An introduction to BGP](/bgp-intro/README.md)
