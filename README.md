Network Examples
================

Welcome to my Linux Networking tutorials. The first part, learning two widely used routing protocols, OSPF and BGP, is almost completed.

## Target audience

You've been a Linux server and network administrator for some years, have been building an office and/or colocation network with IPv4, IPv6, firewalls with IPTables, some stateful filtering (and NAT for IPv4). You've set up VPN tunnels between different locations to be able to reach the internal IPv4 network using RFC1918 addresses on the other side.

You know how to use the `iproute2` programs (`ip a`, `ip r`, etc) to set up your networking, and haven't typed the `ifconfig` or `route` commands in your terminal since 1999. You know how to debug problems using `tcpdump`, `traceroute` etc...

But... your network doesn't show much redundancy. You're pointing a static route to your VPN tunnel to be able to reach the other side, and when you connect a third location, you're realizing that this way of working is getting more and more painful.

You're googling the interwebz for tutorials about an introduction to routing protocols, and discover that most of them start out with a huge amount of theoretical information, and then teach you how to configure Cisco equipment.

You found out that there's helper software to make routing more dynamic, like BIRD, but you have no idea where to start. You don't have money to buy physical routers and switches and cables to connect them, and got a headache after once playing around with a cisco simulator for an hour, missing your cozy linux command line.

## Does the web need more tutorials on these topics?

There aren't a lot of tutorials that take a practical approach, ignoring most of the theory that's not yet needed to be known before just starting to explore the working of e.g. a routing protocol. In my opinion there is really no use in first of all learning that "a type 5 AS-external Link State Advertisement is not allowed in a Not So Stubby Area, unless it's a type 7 Link State Advertisement, that has been converted to a type 5 at an Area Border router, which makes it possible to traverse a..." whatever... :o)

And, while BIRD (the routing software used in these tutorials) has good reference documentation, it's missing tutorial-style documentation for new users. Even if you already know routing protocols, these tutorials should be a quick way to learn using BIRD and some of its quirks on Linux.

I hope that while following the tutorials, you're going to experience the "Wow!" moments, that "make the penny drop" and suddenly make you understand a lot more about complex networking topologies on the internet. Just reading the pages will not make that happen, setting up the examples and doing the assignments will.

Depending on your current knowledge and experience, following the tutorials can take quite some time. This is normal. Don't skip pages or part of them, because when writing, I assume that everything told before is known already. Even though the tutorials are meant as an introduction, there's still already a huge amount of information hidden in them.

Have fun!

## Getting up to speed setting up test environments

All test setups used in the tutorials are built using Linux, LXC and OpenvSwitch for setting up network topologies, and using BIRD as routing daemon.

 * [Setting up a lab environment](/lxcbird/README.md) explains how to set up a local test environment to build example networks using LXC and openvswitch. The result of the tutorial is having a base container that can be cloned into routers and end hosts.
 * [A basic network example](/birdhouse-intro/README.md) provides an introduction to the computer network of a fictional company, the Birdhouse Factory. The tutorial part is to practice some more with setting up a network with containers and openvswitch.

## Learning OSPF and BGP

 * [The Birdhouse Factory continued](/birdhouse-vlans-vpn/README.md) shows how the network at the Birdhouse Factory is evolving, and shows the need for a dynamic routing protocol when multiple routers are introduced.
 * [An introduction to OSPF](/ospf-intro/README.md) explains the basics of using OSPF as an IGP.
 * [An introduction to BGP](/bgp-intro/README.md) shows using BGP to make a connection to an external network that is managed by someone else. Also shows how the routes learned are propagated into the local network, having OSPF and iBGP work together.
 * [A bigger BGP network](/bgp-contd/README.md) shows redundant routes, asymmetric traffic flow and explains the difference between "peering" and "transit".
 * To be finished: [Wait what... The Internet](/routing-on-the-internet/README.md) shows that with the little amount of knowledge we built up about routing, we can suddenly understand how the whole Internet works! (So, fun with traceroute, bgp.he.net, etc...)

## Further ideas

 * Building a pair of stateful filtering IPv4 and IPv6 gateways that can fail over traffic to each other, using `keepalived` and `conntrackd`, while participating in OSPF.
 * Building a load balancer using LVS.
 * Example showcases would be really nice. For example, visiting some IXP that uses BIRD as route server, and doing a writeup of what their network architecture looks like and the been-there-done-thats that they want to share.
 * ...

## Feedback, getting help

 * I'm very interested in feedback on the amount of time it takes to work through the tutorials. Since I wrote them, I cannot predict those, and it may provide useful information about reordering the pages if they're too long.
 * If you like IRC, try the `#bird` channel on Freenode. There's a bunch of friendly BIRD users in there that might help you with the BIRD configuration if you have questions.

Hans van Kranenburg, `hans@knorrie.org`
