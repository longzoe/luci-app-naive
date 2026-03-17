# luci-app-naive

`luci-app-naive` is an OpenWrt LuCI application for managing a manually installed NaiveProxy client.

This package does not depend on the `naiveproxy` OpenWrt package. You copy the NaiveProxy binary to the router yourself, then use the LuCI page to configure and start it.

## Features

- Chinese LuCI interface
- Standard `procd` service management
- Configurable binary path
- Runtime generation of `config.json`
- Optional extra startup arguments
- Binary availability check in the LuCI page

## Repository Layout

- `luci-app-naive/Makefile`: OpenWrt package definition
- `luci-app-naive/luasrc/controller/naive.lua`: LuCI controller and log view
- `luci-app-naive/luasrc/model/cbi/naive/config.lua`: LuCI configuration form
- `luci-app-naive/root/etc/init.d/naive`: `procd` init script
- `luci-app-naive/root/etc/config/naive`: default UCI config

## Build

Copy this package directory into an OpenWrt source tree:

```sh
cp -r luci-app-naive /path/to/openwrt/package/
cd /path/to/openwrt
make menuconfig
make package/luci-app-naive/compile V=s
```

## Install

After installing the generated `ipk`, copy your NaiveProxy binary to the router and make it executable:

```sh
scp naive root@router:/usr/bin/naive
ssh root@router chmod +x /usr/bin/naive
```

Then open LuCI:

`Services -> NaiveProxy`

Configure:

- binary path
- local listen address and port
- upstream protocol
- server, username, and password
- optional extra arguments

## Notes

- If the username or password contains reserved URL characters, encode them before saving.
- `extra_args` is split by spaces and appended to the command line.
- The service generates `config.json` at runtime under `/var/etc/naive/`.
