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
$ docker run -d --name=motortown -p 27015:27015/tcp -p 27015:27015/udp -p 7777:7777/tcp -p 7777:7777/udp dominicrico/motortown
```

Running using Docker with web api:
```console
$ docker run -d --name=motortown -e ENABLE_WEB_API=true -p 27015:27015/tcp -p 27015:27015/udp -p 7777:7777/tcp -p 7777:7777/udp -p 8080:8080/tcp dominicrico/motortown
```

Running using a bind mount for data persistence on container recreation:
```console
$ mkdir -p $(pwd)/motortown-data
$ chown 1000:1000 $(pwd)/motortown-data # Makes sure the directory is writeable by the unprivileged container user with uid 1000, known as steam
$ docker run -d --name=motortown -v $(pwd)/motortown-data:/home/steam/motortown-dedicated/ -p 27015:27015/tcp -p 27015:27015/udp -p 27020:27020/udp dominicrico/motortown
```

or using docker-compose, see [examples](https://github.com/dominicrico/motortown/blob/main/examples/docker-compose.yml):
```console
# Remember to update passwords in your compose file
$ docker compose --file examples/docker-compose.yml up -d motortown-server
```

You must have at least **5GB** of free disk space! See [System Requirements](./#system-requirements).

**The container will automatically update the game on startup, so if there is a game update just restart the container.**

# Configuration

## System Requirements

Minimum system requirements are:

* 2 CPUs
* 2GiB RAM
* 5GB of disk space for the container or mounted as a persistent volume on `/home/steam/motortown-dedicated/`
  * Note: More space may be required if you plan to install mods

## Environment Variables
Feel free to overwrite these environment variables, using -e (--env):

**Note:** `/` characters in the environment variables **must be escaped** as `\/` (e. g. `SERVER_HOSTNAME="My Server 1\/3"` will result in `My Server 1/3` in-game). Otherwise, this may cause unexpected behavior during configuration processing 

### Server Configuration

```dockerfile
SERVER_HOSTNAME="motortown private server"  (Set the visible name of your server.)
SERVER_MESSAGE="Welcome!\nHave fun!"        (Welcome message to greet new players joining your server.)
SERVER_PASSWORD=""                          (Set a server password if you want to keep it private.)
MAX_PLAYERS=10                              (Maximum player count.)
MAX_PLAYER_VEHICLES=5                       (Set the amount of vehicles players allowed to own.)
ALLOW_COMPANY_VEHCILES=false                (Are players allowed to bring their company vehicles.)
ALLOW_COMPANY_AI=true                       (Allow players to use AI for their companies.)
MAX_HOUSING_RENTAL_PLOTS=1                  (Amount of housing rental plots a player is allowed to rent.)
MAX_HOUSING_RENTAL_DAYS=7                   (Amount of days a rental plot is allowed to rent.)
HOUSING_RENTAL_PRICE_RATIO=0.1              (Price ratio of rental plots.)
ALLOW_MODDED_VEHICLES=false                 (Allow modded vehciles on your server.)
NPC_VEHICLE_DENSITY=1.0                     (Set the ai vehicle density.)
NPC_POLICE_DENSITY=1.0                      (Set the ai police density.)
ENABLE_WEB_API=false                        (Enables the web api interface.)
WEB_API_PASSWORD=""                         (Set a web interface password.)
WEB_API_PORT=8080                           (Set the port for the web interface.)
```

**Note:** When using `ENABLE_WEB_API` don't forget to map the port chosen with TCP protocol (e.g., add `-p 8080:8080/tcp` on the `docker run` command or add the port to the `docker-compose.yml` file).

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
