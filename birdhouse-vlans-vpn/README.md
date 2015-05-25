# The Birdhouse Factory continued

## A larger network

While we were [playing around with linux containers](/birdhouse-intro/README.md), Carl, the Birdhouse Factory syadmin has been busy expanding the computer network at the Birdhouse Factory!

![Birdhouse network with vlans and vpn](/birdhouse-vlans-vpn/birdhouse-vlans-vpn.png)

Instead of only having a simple NAT router with a single vlan for a server and a few workstations, the following new elements have been introduced:

 * Three different vlans have been created, to split networks for workstations of employees in the main office, internal servers and the warehouse, which has network-connected manufacturing equipment.
 * VPN server software has been installed to provide employees with the ability to work outside the office. Carl has configured the VPN to push a route to clients that contains all three office vlans, `10.1.32.0/19`.
 * A branch office has been opened in a new location, and an IP in IP tunnel has been established to provide access to the servers in the main office.
 * Using the firewall on the main office gateway, access is granted from the office network and remote branch office network to the internal server network, but not between workstations in different locations, and not from workstations to the warehouse network.

## Separating concerns...

One thing that's bothering Carl is the amount of functionality that's currently running on the single router "sparrow". Besides being the office gateway, it's also a VPN server and gateway to an external office now. But, not visible in the picture, it's also a webmail proxy, backup server, it runs nagios and munin and an outgoing mail relay.

In order to make maintenance and upgrades easier, Carl would like to refactor the network in a way so that functionality is split over multiple servers.

## Separate routers

Carl fires up his network diagram editor, loads the drawing of his network layout, and starts changing it:

![Birdhouse network with split routers](/birdhouse-vlans-vpn/birdhouse-vlans-vpn-split.png)

Two new routers have been introduced here, a separate VPN gateway, "pigeon", and a separate IP tunnel gateway "owl".

Both of the new routers have an interface in the public network:

 * The VPN server "pigeon" needs to have a public accessible IP address for VPN clients to connect to.
 * The tunnel gateway connecting the branch office to the internal network needs a public address to be able to connect to the remote tunnel endpoint.

Although this is a nice first step, Carl realizes it's not ready yet. Something is missing.

The internal network has been split up, and the various parts of it cannot communicate with each other any more. Using the public network segment to point RFC1918 routes to the other routers is not really an option, since it will result in complex firewall/NAT exceptions, because of the SNAT rules for outgoing traffic, which rewrite the RFC1918 addresses. So, as a best-practice, Carl does not like to mix RFC1918 with public routable addresses on the same vlan, knowing it will cause too many headaches.

![Birdhouse network with split routers and internal routing vlan](/birdhouse-vlans-vpn/birdhouse-vlans-vpn-split-routing-vlan.png)

Using this extra vlan, each router can be configured with routes to the rest of the network. This is already much better.

However, the next question immediately rises... In order to make sure each part of the network can be reached from each other part, Carl would have to program all the following routes into the separate routers:

Office Gateway "sparrow":  
 * `10.1.18.0/24 via 10.1.32.3`
 * `10.1.33.66/31 via 10.1.32.3`
 * `10.1.62.0/24 via 10.1.32.2`

VPN Gateway "pigeon":  
 * `10.1.18.0/24 via 10.1.32.3`
 * `10.1.33.66/31 via 10.1.32.3`
 * `10.1.59.0/24 via 10.1.32.1`
 * `10.1.60.0/24 via 10.1.32.1`
 * `10.1.63.0/24 via 10.1.32.1`

Tunnel gateway "owl":  
 * `10.1.59.0/24 via 10.1.32.1`
 * `10.1.60.0/24 via 10.1.32.1`
 * `10.1.62.0/24 via 10.1.32.2`
 * `10.1.63.0/24 via 10.1.32.1`

Carl realizes this is going to turn into a real nightmare when the network keeps expanding in the future, and starts looking for a better way to handle all the routes.

It would be cool if the routers could just talk to each other on the internal routing lan and tell each other which networks are reachable via them...
