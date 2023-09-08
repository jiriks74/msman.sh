# DEVELOPMENT CONTINUES AT https://gitea.stefka.eu/jiriks74/msman.sh

# MinecraftServerMANager

The best way to quicky spin spin up a Minecraft server

This project is a successor to [start_papermc.sh](https://github.com/jiriks74/start_papermc.sh)
specifically the [v2.0.0](https://github.com/jiriks74/start_papermc.sh/tree/v2.0.0)
branch.
The project grew out of the scope I envisioned at first, surprisingly quickly LOL,
so I moved all my development here.

This project aims to support more minecraft servers rather than just paper.

## Features

#### Takes care of Java

- Checks for the correct Java version installed
- Enables you to download a download a portable Java version from [Adoptium](https://adoptium.net/)
  - The script download's it to `~/.adoptium_java` allowing you to use one
  Java downlaod across multiple server instances
  - It also allows you to use multiple Java versions allowing you to run
  multiple Minecraft servers requiring different Java versions

#### Simple setup

- To setup your server you only need to change some values in `msman.cfg`
  - If you're starting a server just for you and your friends you don't need to
  change anything apart from the version and memory usage
- Values like memory are easy to change without the need to undertand Java flags
- Asks you if you want to accept the eula so you don't need to mess around with `eula.txt`

#### Sane defaults

- Uses [Aikar's flags](#default-jvm-flags-used)

#### Protections

- Makes sure you really meant to update the Minecraft version

#### Self-update

- This script can self-update itself without the need for user doing it manually

## Currently supported servers

- [Paper](https://papermc.io/)
- [Fabric](https://fabricmc.net/use/server/)

## Dependencies

- `jq`
- `awp`
- `curl`

*Most, if not all, of these should be already available on your system if
you're running something like Ubuntu.*

## Precautions

> **Warning**
>
> It is important to note that this script manages the server's `.jar` file,
> including its name.
>
> Any modifications made to the `.jar` file outside of this script can lead to
> undefined behavior and may cause the script to crash or perform unexpected actions.
>
> I strongly advise against making any modifications to the server's `.jar` file
> manually, as it may interfere with the proper functioning of this script.

## Basic setup

- Option 1: Oneliner

```bash
curl -sSL "https://raw.githubusercontent.com/jiriks74/msman.sh/main/msman.sh" -o msman.sh && chmod +x msman.sh && ./msman.sh
```

- Option 2: Download `msman.sh` from release to where you want your minecraft
server and start it with

```bash
chmod +x msman.sh
./msman.sh
```

- Option 2: Clone the repository

```bash
git clone https://github.com/jiriks74/msman.sh minecraft_server
cd minecraft_server
chmod +x msman.sh
./msman.sh
```

## Updating the server

### Builds

This script can automatically update to the latest papermc build available for
the Minecraft version you selected.
If you want this behaviour, leave the select_build veriable empty.
Otherwise select the build you want and the script will download it for you.

## Default JVM flags used

By default this script uses [Aikar's](https://docs.papermc.io/paper/aikars-flags)
flags.
It's set up so that it automatically modifies them if over 12GB of memory
is set for the server so you shouldn't need to change them unless you
want to swap them out for something else.
