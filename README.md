# WireSocks-MultiTunnel

Setup Scripts, docker-compose.yml and Dockerfile to set up a wireguard VPN connection and 
forcing (specific) TCP traffic through a socks proxy.

This builds on top of [WireSocks](https://github.com/sensepost/wiresocks), but aims at a different use case.
It might be possible to integrate both into each other, but at this point, this repo provides a solution to route
ALL traffic of a wireguard peer through a local or external socks proxy, but also allowing different peers to use
individual proxies, for example if you want to specify which peer to use a specific Proxy / IP to gain access to specific networks.

This allows for the following setup:
```
Client 1 -> Wireguard Server -> Proxy 1 -> Target Network
Client 2 -> Wireguard Server -> Proxy 2 -> Target Network
....
Client X -> Wireguard Server -> Proxy X -> Target Network
```

## Warning

`docker-compose` provided by ubuntu (and other distributions) is old and doesnt support versions that allow networking fancyness.
Please make sure you are using a recent version of `docker-compose`.
One way to check if you have a recent enough version is to run `docker compose version`.
If either the command is not available, or the version reported is not at least version 2.10+, then you need to upgrade.

### Upgrade Instructions (taken from [here](https://stackoverflow.com/questions/49839028/how-to-upgrade-docker-compose-to-latest-version)):

First, remove the old version:

If installed via **apt-get**: `sudo apt-get remove docker-compose`

If installed via **curl**: `sudo rm /usr/local/bin/docker-compose`

If installed via **pip**: `pip uninstall docker-compose`

Then find the newest version, download it and install it:
```
VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*\d')
DESTINATION=/usr/local/bin/docker-compose
sudo curl -L https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$(uname -s)-$(uname -m) -o $DESTINATION
sudo chmod 755 $DESTINATION
```

## Usage

A `docker-compose` has been provided to setup both the tun2socks and wireguard.

Copy the example `.env.example` file to `.env` and tweak the values as needed (it should have enough documentation to know what each value is for). Then, start the stack with:

```bash
docker-compose up -d
```

You can view the logs from tun2socks to check what is being proxied and errors with:

```bash
docker-compose logs -f
```

The docker-compose will also setup wireguard and you should be able to find the peer config you want to use in the `./config/peer*` directories (depending on how many peers you configured). Grab that and import it into your client where you want to proxy communications from.

**Note:** In some cases it may be useful to add the `PersistentKeepalive = 2` directive in the `[peer]` section if you experience random timeouts.

Now all traffic should be forced through the SOCKS proxy without hastle for the networks you want to reach, together with DNS.

### DNS

For DNS we leverage CoreDNS to translate DNS requests for a specific domain and forward them using a TCP lookup. This effectivly gets us DNS through the SOCKS tunnel.

## Technical Details

Below is some more technical information about the containers used in the docker-compose.yml file.

### Information about the tun2socks docker (wiresocks)

The wiresocks service runs a docker image with `--cap-add=NET_ADMIN --sysctl="net.ipv4.ip_forward=1" --device=/dev/net/tun:/dev/net/tun` flags to allow the container to create a tun interface as well as set routes for it.

You specify the socks proxy using the `PROXY` environment variable, make sure your docker can reach that proxy. It the same as the `-e` flag given to `tun2socks`.

```text
-e PROXY=socks5://socksaddress:1080
```

You can also specify which ranges you want to have redirected to the socks proxy by providing a `TUN_INCLUDED_ROUTES` environment variable:

```text
-e TUN_INCLUDED_ROUTES=192.168.165.0/24
```

The `TUN_INCLUDED_ROUTES` may be comma seperated for multiple ranges.

The container will start tun2socks and configure routes to forward traffic of the routes provided in `TUN_INCLUDED_ROUTES` through the created TUN interface.

### Socksing other dockers

You can use the `--net container:wiresocks` option with other docker containers to get them to share the same network namespace as the wiresocks docker. This includes the setup routes as well as access to the TUN interface. This essentially means you can tunnel arbitary dockers using tun2socks with this option. In the docker-compose we use it for WireGuard so that Windows/MacOS just need a WireGuard config and they can have their traffic transparently proxied.

## Other

### Thanks

The original idea used Darkks [redsocks](https://github.com/darkk/redsocks/) which is amazing!

This version uses the equally amazing [tun2socks](https://github.com/xjasonlyu/tun2socks) by xjasonlyu!

Uses [LinuxServers wireguard](https://github.com/linuxserver/docker-wireguard) image to setup the wireguard vpn to connect into the socks network

## license

`WireSocks` is licensed under a [GNU General Public v3 License](https://www.gnu.org/licenses/gpl-3.0.en.html). Permissions beyond the scope of this license may be available at <http://sensepost.com/contact/>.
