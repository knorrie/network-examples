BGP
===

Blablabla, work in progress here.

In the [previous tutorial, we discovered how to let OSPF dynamically configure routing](/ospf-intro/README.md) in a network.

This tutorial provides an introduction to another routing protocol, which is BGP, the Border Gateway Protocol.

BGP is not an alternative to OSPF. It's used for different things.

To start off quickly, here's the bare essentials:

![BGP network, barebones](/bgp-intro/bgp-heythere.png)

When routers talk BGP to each other, they just claim that some network ranges are reachable via them. Voila.

Ok, a bit less simplified:

![BGP network, less simplified](/bgp-intro/bgp-hey2.png)

 * Between routers: small subnet, like an IPv4 /30 or /31, which only contains the two routers.
 * Often direct links, in this bird/openvswitch tutorial just use a vlan
 * A complete network under control of somebody has an AS number, an Autonomous System

## OSPF vs. BGP

While the title of this section might seem logical, since we're considering BGP after just having spent quite some time on OSPF, it's actually a non-issue. OSPF and BGP are two very different routing protocols, which are used to get different things done.

OSPF:
 * routes in the network are originated by putting ip addresses on a network interface of a router, not manually defined
 * these are addresses and subnets that are actually in use
 * every router has a full detailed view on the network using link state updates that are broadcasted over the network

BGP:
 * only publish "umbrella" ranges, not much detail
 * there is no actual proof that the addresses are actually in use.
 * routers know that some prefix is reachable via another network, but where OSPF shortest path deals with knowledge about all separate routers, paths and weights, BGP just looks on a higher level, the shortest path, considering a complete network being one step.

So, OSPF is an IGP (Interior Gateway Protocol) and BGP is an EGP (Exterior Gateway Protocol). BGP can connect OSPF networks to each other, hiding a lot of detail inside them.

![BGP network, three ASses](/bgp-intro/bgp-hey3.png)

R2 tells R3 that it may send traffic for `10.2.0.0/16` and `10.1.0.0/16` to it. It also provides an AS-path with each route. The route `10.2.0.0/16` only has `65002` as AS-path, so R3 knows that this route originates from `AS65002`. The route `10.1.0.0/16` has an AS-path of `65002,65001`, so R3 will learn that this route actually originates from `AS65001`, and apparently `AS65002` wants to relay traffic to it through its own network.

But, later. First of all, do it with bird, build full example.

## BIRD BGP

![BGP and OSPF network](/bgp-intro/bgp-ospf.png)

Whoa, such network.

Hopsa, clone some containers, copy paste configuration
 * already provide bird config with ospf for internal network

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
