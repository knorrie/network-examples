OSPF
====

In this tutorial, I'll explain a bit about how the OSPF routing protocol works, followed by a full hands-on tutorial to practice and see it in action yourself!

In the previous page of this tutorial series, we met the Birdhouse Factory sysadmin Carl, who was about to get a little depressed about the amount of manual work he needed to do to get his newly created set of routers forward traffic into the right direction. He wondered if there would be a better way to do this, having the routers just tell each other what traffic should go where.

Luckily, such a thing actually exists. Instead of programming all routers in detail with the next hop for each possible subnet that exists in the network, it's possible to let the routers figure this out themselves.

The first dynaminc routing protocol that we'll be using in this tutorial series is the OSPF routing protocol. The topology of an OSPF network is not laid out in advance. The network completely discovers itself "on the go".

### Step one: separate routers with interfaces

The network in this tutorial has four routers. Each of these routers has connections to multiple networks:

![OSPF network, separate](/ospf-intro/ospf-separate.png)

Each of the four routers is shown as a little "card" with information on it, which contains:

 * A unique IP address-like number (in bold), which is a so called 'Router ID'.
 * Several interfaces, which are connected to different subnets, having a unique address in each of those subnets.
 * A "stub" sign that is either missing or present on the interface.

If the network is a "stub", it's like a dead end road, and we expect that the network contains end hosts (like servers and workstations), but no other routers. If the network is not a stub, we consider it a network where other routers are present, and usually no end hosts.

So what's different between the network drawings of the Birdhouse Factory that we've seen in the previous tutorials? On the last page, we learned that sysadmin Carl had designed the whole network on paper first, and then had to program all routes to other networks into each router in the network. The image above looks like the complete opposite. We have four routers, and each of them only knows about it's directly connected subnets, and has no idea at all about the existence of the other three routers.

This seems strange, but it's an ideal starting point for a dynamic routing protocol like OSPF.

### Step two: activating OSPF, discovering network topology

When looking at the picture with the four separate routers, you should already have noticed that some of the interfaces of different routers share the same subnet. For example, `10.0.1.5` of R1 and `10.0.1.4` of R5 are in the same subnet, and connected to the same vlan. This means they should be able to communicate with each other. Only, they don't know each other. Yet. `10.0.1.5` does not know there's a router on `10.0.1.4`, and not maybe on `10.0.1.23` or any other address.

The fun with OSPF is that the routers do not need to know information about other routers at all at first, because all of it will be discovered dynamically. When starting up, each router is programmed with just enough information about itself, which is the Router ID, connected subnets and the knowledge if a connected network is a stub (no routers to be expected there) or not. With this information, the router can assemble it's own "information card", like the four ones shown above.

To discover the full topology of the network, all of the routers do the following:

 * Send out the information card of the router itself on *all* interfaces that are likely to be able to directly reach other routers (so interfaces that are not a stub).
 * Listen for information of other routers on interfaces that are not a stub.
 * When an information card of a router arrives, store it, and send it out again on all other interfaces that are not a stub, unless the information of this particular router was already received before.

And magically... After a short burst of network traffic, all routers have now received each other's information, and are in possesion of the four cards with information. It really works. You can even try it yourself, by printing the image a few times, cutting out the little paper pieces and replaying it manually!

Now that each router has all information about the other ones, let's see what happens when we simply connect them together, turning the shared subnet ranges into a subnet between the routers:

![OSPF network, joined together](/ospf-intro/ospf-together.png)

Each of the four routers can do this, and each of them now has an overview of the complete topology of the network! And, all of them have the exact same one, which is actually a very important fact.

### Step three: figuring out the shortest path, and setting next-hops

I just realized I've been talking about OSPF on this page without ever explaining what it means. OSPF is an abbreviation of "Open Shortest Path First". These four words just describe what OSPF is supposed to do. Given the topology of the network, which we've just discovered by sharing all information cards of all routers wich each other and connecting them together, it's possible to find out the shortest path to every subnet (being stub or not) in the picture. If you want to know how this is done, look up the "Dijkstra" algorithm, which is the mathematical algorithm that is used by OSPF.

However, to be able to actually forward network traffic, the OSPF process has to tell the linux kernel what routes to add to the kernel routing table to get traffic going into the right direction. It needs to do so, because the OSPF process is just the process that is communicating with other routers, it's not the process that is in charge of actually handling the forwarding of network traffic. Doing the packet forwarding is the task of the linux kernel itself.

You know that the linux kernel works with routes that can point to a next router in a connected subnet only, like the list of routes that Birdhouse Factory sysadmin Carl had to enter into all of his routers. If I am the OSPF process on R2 (10.9.99.2), I know that the network `10.34.2.0/24` lies hidden behind R6. But, I cannot just tell the linux kernel to add a route "10.34.2.0/24 via 10.0.1.8", because 10.0.1.8 is not in a connected subnet. What the OSPF process can do, is tell the linux kernel to add a route to an intermediate next hop, which would be either "10.34.2.0/24 via 10.1.2.56" or "10.34.2.0/24 via 10.1.2.7".

The fun part here is that each of the participating routers in the OSPF network knows exactly the same amount of information about the whole network topology, and uses the same way to calculate the shortest routes from itself to all subnets that exist in the network. So, it's not a problem at all that the OSPF process on R2 can only tell the linux kernel to forward packets for `10.34.2.1` to a next hop of `10.1.2.56`, because it can trust on the fact that R5 will always forward them again to `10.0.1.8`, having R6 receive them, which will drop them into the connected subnet to reach the end host in there.

### Hands on!

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
