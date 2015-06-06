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

![OSPF network with discovered neigbours](/ospf-intro/ospf-neighbours.png)

Now, the upper part of the network contains three routers which know they are neigbours, as does the lower part. But, router 2 and 6 do not know about each others existence yet.

### Discovering the full network topology

To discover the full topology of the network, the following happens:
 * Send out the complete information card of the router itself, with all information of active "links" that the router has to all neighbours.
 * Receive the same information from neighbour routers.
 * When an information card of a router arrives, store it, and send it out again on all other interfaces that are not a stub, unless the information of this particular router was already received before.

And magically... After a short burst of network traffic, all routers have now received each other's information, and are in possesion of the four cards with information. Now that each router has all information about the other ones, let's see what happens when we simply connect them together, turning the shared subnet ranges into a subnet between the routers:

![OSPF network, joined together](/ospf-intro/ospf-together.png)

And now here's a very important characteristic of the OSPF protocol: *Each* of the four routers can do this, and each of them now has an overview of the complete topology of the network! And, all of them have the *exact* same one.

## Step three: figuring out shortest paths and determining next-hops

Now that each router has gathered enough information to assemble a complete detailed map of the complete network, the meaning of the abbreviation OSPF comes into play. OSPF means "Open Shortest Path First". Using the details of the network topology map, it's possible to find out the shortest path to every subnet that exists in the network (being stub or not). If you want to know how this is done, look up the Dijkstra's algorithm, which is the mathematical algorithm that is used by OSPF.

While each router can determine the complete shortest path to any destination in the network, it might sound quite disappointing to know that most of this valuable information can not be used by any individual router to get an IP packet to its destination.

 * First of all, the routing software (for which BIRD will be used in these tutorials) is not in charge of the forwarding of packets itself (which is done by the Linux kernel in these examples). This difference is well known as the difference between a "Control Plane" and a "Forwarding Plane", which have nothing to do with aircrafts.
 * The routing sofware (control plane) has to program the kernel (forwarding plane) with a next hop router for each existing subnet in the network, and it can not provide more information than just that next hop, which has to be in a directly connected subnet. So the OSPF routing process knows much more about the path that the to be forwarded packet will travel than it is able to tell the forwarding path.

And why shouldn't we care too much about all of this? The fun part here is that each of the participating routers in the OSPF network knows exactly the same amount of information about the whole network topology, and uses the same way to calculate the shortest routes from itself to all subnets that exist in the network. So, it's not a problem at all that the OSPF process on R2 can only tell the linux kernel to forward packets for `10.34.2.89` to a next hop of `10.1.2.56`, because it can trust on the fact that R5 will always forward them again to `10.0.1.8`, having R6 receive them, which will drop them into the connected subnet to reach the end host in there.

If you're confused now, don't worry. Take a short break and continue with the hands-on part to see it all happen!

If you're not confused yet, here's some bonus information to think about: To make it even worse, the IP address of this next hop is not even used when actually forwarding a packet to the next router! It's only being used to determine the layer 2 mac address of the interface of the next hop. :-) An IP packet contains a source and a destination IP address. It does not contain a list of routers that it needs to pass before reaching its destination. It does not even contain the address of the very first next hop that it needs to go to, and the receiving next router has no idea where the packet it just received has been, or which IP address was used to forward it. It only sees the mac address of the sending router.

# Hands on!

Enough of this theoretical babble! Let's create the network ourselves, using some linux containers and vlans with openvswitch!

Ok, first of all, to be honest, the stub links still look a bit sad, so let's connect a host to them, which we will use later, when we'll actually building the network, to execute tests between them to see if they can reach each other, and if so, using what route over the network:

![OSPF network, joined together with some hosts](/ospf-intro/ospf-together-hosts.png)

### Building the containers

Let's build some containers!

 * -> clone containers
 * -> setup interfaces
 * -> copy config
 * -> start all containers
 * -> verify in containers that you can `ip r` and only see connected networks

To be able to use the OSPF routing protocol, we need to run a program on each router that implements it. BIRD, the BIRD Internet Routing Daemon is one of those and I'll be using it for all examples and tutorials here. Blah container cloned from birdbase already has bird blah.

Since the network interfaces and IP addresses of connected subnets are already defined in the operating system configuration, we only need to provide the following extra information to be able to start using the OSPF routing protocol:

 * A 32 bit number, the Router ID, which is a unique identifier of this router. We'll use the 10.9.99.X address of each router for that.
 * A list of interfaces which should participate in the OSPF network, and whether the interfaces are or are not a stub interface.

Blah default config file, add OSPF config, `ip r`, `ip a`, interfaces, blah blah etc...
