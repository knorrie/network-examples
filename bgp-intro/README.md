BGP
===

In the previous tutorial, we discovered how to let [OSPF](/ospf-intro/README.md) dynamically configure routing inside a network. This tutorial provides an introduction to another routing protocol, which is BGP, the Border Gateway Protocol. As the name implies, this protocol acts on the border of a network. Where OSPF is well suited to keep track of all tiny details of what's happening in our internal network, BGP will be talking to the outside world to interconnect our network with other networks, managed by someone else.

## BGP Essentials

When routers talk BGP to each other, they essentially just claim that network ranges are reachable via them:

![BGP network, barebones](/bgp-intro/bgp-heythere.png)

Let's look at the same picture again, hiding less information:

![BGP network, less simplified](/bgp-intro/bgp-hey2.png)

The picture shows two networks, which are interconnected through router `R3` and `R10`.

 * A complete network under control of somebody has an AS ([Autonomous System](https://tools.ietf.org/html/rfc1930)) number. By specifying the AS number when configuring BGP connections, we let it know if the neighbour is in our own network (our AS), or in an external network (another AS).
 * If neighbouring routers between different networks are directly connected, they often interconnect using a minimal sized network range. For IPv4, this is usually a `/30` and for IPv6 a `/120` or a `/126` prefix, containing only the two routers. In the example above, the small network ranges are taken from the network of `AS64080`.
 * The routes that are published to another network are as aggregated as possible, to minimize the amount of them. While the internal routing table in for example AS64080 might contain dozens of prefixes, for each little vlan, and probably a number of single host routes (IPv4 `/32` and IPv6 `/128`), they're advertised to the outside as just three routes in total.

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

It's starting to look serious now!

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
