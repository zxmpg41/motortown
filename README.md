[![Docker Image CI](https://github.com/dominicrico/motortown/actions/workflows/docker-image.yml/badge.svg?branch=main)](https://github.com/dominicrico/motortown/actions/workflows/docker-image.yml) [![Docker Build and Publish](https://github.com/dominicrico/motortown/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/dominicrico/motortown/actions/workflows/docker-publish.yml)

# What is Motor Town?
Motor Town: Behind The Wheel is an open-world driving simulator that combines realistic vehicle physics with a variety of activities like deliveries, racing, and taxi driving. It features single-player and multiplayer modes, offering a relaxing yet engaging driving experience.

This Docker image contains the dedicated server of the game.

>  [Motor Town: Behind The Wheel](https://store.steampowered.com/app/1369670/Motor_Town_Behind_The_Wheel/)

<img src="https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1369670/header.jpg?t=1743269133" alt="logo" width="300"/></img>

# How to use this image
## Hosting a simple game server

Running using Docker:
```console
$ SRCDS_TOKEN="..." # check https://steamcommunity.com/dev/managegameservers
$ docker run -d --name=motortown -e SRCDS_TOKEN="$SRCDS_TOKEN" -p 27015:27015/tcp -p 27015:27015/udp -p 7777:7777/tcp -p 7777:7777/udp dominicrico/motortown
```

Running using Docker with web api:
```console
$ SRCDS_TOKEN="..." # check https://steamcommunity.com/dev/managegameservers
$ docker run -d --name=motortown -e ENABLE_WEB_API=true -e SRCDS_TOKEN="$SRCDS_TOKEN" -p 27015:27015/tcp -p 27015:27015/udp -p 7777:7777/tcp -p 7777:7777/udp -p 8080:8080/tcp dominicrico/motortown
```

Running using a bind mount for data persistence on container recreation:
```console
$ mkdir -p $(pwd)/motortown-data
$ chown 1000:1000 $(pwd)/motortown-data # Makes sure the directory is writeable by the unprivileged container user with uid 1000, known as steam
$ SRCDS_TOKEN="..." # check https://steamcommunity.com/dev/managegameservers
$ docker run -d --name=motortown -e SRCDS_TOKEN="$SRCDS_TOKEN" -v $(pwd)/motortown-data:/home/steam/motortown-dedicated/ -p 27015:27015/tcp -p 27015:27015/udp -p 27020:27020/udp dominicrico/motortown
```

or using docker-compose, see [examples](https://github.com/dominicrico/motortown/blob/main/examples/docker-compose.yml):
```console
# Remember to update passwords and SRCDS_TOKEN in your compose file
$ docker compose --file examples/docker-compose.yml up -d motortown-server
```

You must have at least **50GB** of free disk space! See [System Requirements](./#system-requirements).

**The container will automatically update the game on startup, so if there is a game update just restart the container.**

# Configuration

## System Requirements

Minimum system requirements are:

* 2 CPUs
* 2GiB RAM
* 50GB of disk space for the container or mounted as a persistent volume on `/home/steam/motortown-dedicated/`
  * Note: More space may be required if you plan to install mods

## Environment Variables
Feel free to overwrite these environment variables, using -e (--env):

**Note:** `/` characters in the environment variables **must be escaped** as `\/` (e. g. `SERVER_HOSTNAME="My Server 1\/3"` will result in `My Server 1/3` in-game). Otherwise, this may cause unexpected behavior during configuration processing 

### Server Configuration

```dockerfile
SRCDS_TOKEN=""              (Game Server Token from https://steamcommunity.com/dev/managegameservers)
SERVER_HOSTNAME="changeme"   (Set the visible name for your private server.)
CS2_CHEATS=0                (0 - disable cheats, 1 - enable cheats)
CS2_SERVER_HIBERNATE=0      (Put server in a low CPU state when there are no players. 
                             0 - hibernation disabled, 1 - hibernation enabled
                             n.b. hibernation has been observed to trigger server crashes)
CS2_IP=""                   (CS2 server listening IP address, 0.0.0.0 - all IP addresses on the local machine, empty - IP identified automatically)
CS2_PORT=27015              (CS2 server listen port tcp_udp)
CS2_RCON_PORT=""            (Optional, use a simple TCP proxy to have RCON listen on an alternative port.
                             Useful for services like AWS Fargate which do not support mixed protocol ports.)
CS2_LAN="0"                 (0 - LAN mode disabled, 1 - LAN Mode enabled)
CS2_RCONPW="changeme"       (RCON password)
CS2_PW=""                   (Optional, CS2 server password)
CS2_MAXPLAYERS=10           (Max players)
CS2_ADDITIONAL_ARGS=""      (Optional additional arguments to pass into cs2)
```

**Note:** When using `CS2_RCON_PORT` don't forget to map the port chosen with TCP protocol (e.g., add `-p 27050:27050/tcp` on the `docker run` command or add the port to the `docker-compose.yml` file).

# Customizing this Container

## Validating Game Files

If you break the game through your customisations and want steamcmd to validate and redownload then set the `STEAMAPPVALIDATE` environment variable to `1`:

```dockerfile
STEAMAPPVALIDATE=0          (0=skip validation, 1=validate game files)
```

## Pre and Post Hooks

The container includes two scripts for executing custom actions:

* `/home/steam/motortown-dedicated/pre.sh` is executed before the CS2 server starts
* `/home/steam/motortown-dedicated/post.sh` is executed after the CS2 server stops

When using a persient volume mounted at `/home/steam/motortown-dedicated/` you may edit these scripts to perform custom actions.

Alternatively, you may have docker mount files from outside the container to override these files. E.g.:

```
-v /path/to/pre.sh:/home/steam/motortown-dedicated/pre.sh
```

## Customisation Bundle

The container can be instructed to download a extract a Tar Gzip bundle, Tar or Zip archive of configuration files and other customisations from a given URL.

```dockerfile
MOTORTOWN_CFG_URL=""          (HTTP/HTTPS URL to fetch a Tar Gzip bundle, Tar or Zip archive of configuration files/mods)
```

See [examples](https://github.com/dominicrico/motortown/blob/main/examples/motortown.cfg.tgz) for a correctly formatted Tar Gzip customisation bundle, the same format applies to all archive types.


# Credits

This container leans heavily on the work of [joedwards32](https://github.com/joedwards32) and [CM2Walki](https://github.com/CM2Walki/), especially his [SteamCMD](https://github.com/CM2Walki/steamcmd) container image. GG!
