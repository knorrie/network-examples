Network Examples
================

This is a work in progress.

This page will contain a nice high level story, pointing to parts of the tutorials.

For now, completed pages:

 * [Setting up a lab environment](/lxcbird/README.md) explains how to set up a local test environment to build example networks using LXC and openvswitch. The result of the tutorial is having a base container that can be cloned into routers and end hosts.
 * [A basic network example](/birdhouse-intro/README.md) provides an introduction to the computer network of a fictional company, the Birdhouse Factory. The tutorial part is to practice some more with setting up a network with containers and openvswitch.
 * [The Birdhouse Factory continued](/birdhouse-vlans-vpn/README.md) shows how the network at the Birdhouse Factory is evolving, and shows the need for a dynamic routing protocol when multiple routers are introduced.

## Planned pages

### Learning OSPF and BGP

 * [An introduction to OSPF](/ospf-intro/README.md) explains the basics of using OSPF as an IGP.
 * [Enabling OSPF in the Birdhouse internal network](/birdhouse-ospf/README.md) is a tutorial that will repeat the lessons learned about ospf. The reader will be configuring ospf in the Birdhouse network, to eliminate the mess of maintaining static routes all over the place.
 * [An introduction to BGP](/bgp-intro/README.md) shows using BGP to make a connection to an external network that is managed by someone else. Also shows how the routes learned are propagated into the local network, having OSPF and iBGP work together.
 * [A bigger BGP network](/bgp-contd/README.md) shows asymmetric traffic flow and explains the difference between "peering" and "transit".
 * [Enabling BGP between Birdhouse locations](/birdhouse-bgp/README.md) makes the reader configure BGP in the internal Birdhouse network, implementing redundancy between the two main office locations, and also adding a third office.
 * [Wait what... The Internet](/routing-on-the-internet/README.md) shows that with the little amount of knowledge we built up about routing, we can suddenly understand how the whole Internet works! (So, fun with traceroute, bgp.he.net, etc...)

### IPv6

 * In [Adding IPv6 to the Birdhouse network](/birdhouse-ipv6/README.md), sysadmin Carl enables IPv6 on the network, and runs into a new routing challenge...
 * [Routing for the public network](/birdhouse-public-routing-vlan) lets the reader apply all lessons learned so far while completely refactoring the public network of the Birdhouse Factory with IPv6, OSPF and BGP.

### Introducing more redundancy

 * In order to be able to do maintenance without downtime, [A second uplink](/birdhouse-second-uplink/README.md) to another router of the same ISP is added in the public Birdhouse network, using two edge routers at the Birdhouse side with VRRP for end hosts.
 * [A redundant default gateway for the office](/birdhouse-vrrp-nat/README.md) shows the extra complexity of running a stateful firewall in combination with VRRP for the access networks in the office.
