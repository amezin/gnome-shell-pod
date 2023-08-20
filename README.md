# GNOME Shell container

Fedora container for testing GNOME Shell extensions on GitHub Actions (and also
locally).

Based on https://github.com/Schneegans/gnome-shell-pod

## How to use

This container runs systemd, both system and user instances. Probably, you
could make it work in Docker with [oci-systemd-hook], but it's not packaged
for Arch (which I use as my workstation distro), or Ubuntu (used on GitHub
Actions runners). So using Podman seems to be the only viable option.

[oci-systemd-hook]: https://github.com/projectatomic/oci-systemd-hook

Note: currently, rootless Podman doesn't work on GitHub Actions runners,
you'll have to run it under `sudo`.

### 1. Start the container using Podman, mount extension sources into `~/.local/share/gnome-shell/extensions/`:

```sh
SOURCE_DIR="${PWD}"
EXTENSION_UUID="ddterm@amezin.github.com"
IMAGE="ghcr.io/ddterm/gnome-shell-pod/fedora-36:master"
PACKAGE_MOUNTPATH="/home/gnomeshell/.local/share/gnome-shell/extensions/${EXTENSION_UUID}"

POD=$(podman run --rm --cap-add=SYS_NICE,SYS_PTRACE,SETPCAP,NET_RAW,NET_BIND_SERVICE,DAC_READ_SEARCH,IPC_LOCK -v "${SOURCE_DIR}:${PACKAGE_MOUNTPATH}:ro" -td "${IMAGE}")
```

### 2. Wait for the system to start:

Wait for system D-Bus to start:

```sh
podman exec "${POD}" busctl --watch-bind=true status
```

Wait for the system to complete startup:

```sh
podman exec "${POD}" systemctl is-system-running --wait
```

### 3. Enable the extension:

```sh
podman exec --user gnomeshell "${POD}" set-env.sh gnome-extensions enable "${EXTENSION_UUID}"
```

## CGroups v1/v2

The default systemd command line sets `systemd.unified_cgroup_hierarchy=0`
(CGroups v1 mode) for compatibility with older distributions on the host side.

## Wayland

By default, X11 session starts.

To start Wayland session, add `systemd.unit=gnome-session-wayland.target` to
the systemd command line:

```sh
podman run --rm --cap-add=SYS_NICE,SYS_PTRACE,SETPCAP,NET_RAW,NET_BIND_SERVICE,DAC_READ_SEARCH,IPC_LOCK -v "${SOURCE_DIR}:${PACKAGE_MOUNTPATH}:ro" -td "${IMAGE}" /sbin/init systemd.unified_cgroup_hierarchy=0 systemd.unit=gnome-session-wayland.target
```

It still runs in Xvfb, but in nested mode. Without window manager running on
the "top level", the window has no decorations, and is effectively full screen.

If you don't want GNOME session to start automatically, you could pass
`systemd.unit=multi-user.target`. Then you could activate the necessary target
manually:

```sh
podman exec "${POD}" systemctl start gnome-session-wayland.target
```

## D-Bus

Session D-Bus daemon is listening on TCP port `1234`. To access it from host,
add `--publish`/`--publish-all` option to `podman run` (see `podman` docs).

To get the host-side port number, use `podman port` command:

```sh
podman port "${POD}" 1234
```

It will output something like:

```
127.0.0.1:42325
```

or

```
0.0.0.0:42325
```

It will translate into D-Bus address `tcp:host=localhost,port=42325`.

For example:

```sh
dbus-send --bus=tcp:host=localhost,port=42325 --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.Peer.Ping
```

Container-side port number (`1234`) is also stored in `user-dbus-port` label.
You could get it using the following command:

```sh
podman container inspect --format='{{index .Config.Labels "user-dbus-port"}}'
```

## X11/Xvfb display

Xvfb starts on display `:99`. If you want to run some X11 utility, you should
add `-e DISPLAY=:99` to `podman exec`.

Also, Xvfb display is available over TCP, on port `6099`. It will be published
by `--publish-all` too.

To get the host-side port number, use `podman port` command:

```sh
podman port "${POD}" 6099
```

It will output something like:

```
127.0.0.1:42325
```

or

```
0.0.0.0:42325
```

You'll need to subtract `6000` from the port number to get X11 display number.

Then run X11 utilities on the host like this:

```sh
DISPLAY=127.0.0.1:36325 xte "mousedown 1"
```

Container-side port number (`6099`) is also stored in `x11-port` label. You
could get it using the following command:

```sh
podman container inspect --format='{{index .Config.Labels "x11-port"}}'
```

## Building the image

### Debian/Ubuntu image

```sh
podman build -f debian.dockerfile --format docker .
```

By default it builds on top of the latest stable Debian release (`debian:latest` on Docker Hub).

` --format docker` is necessary for health check support.

To choose another base image/distro, pass `--build-arg base_image=...`:

```sh
podman build -f debian.dockerfile --format docker --build-arg base_image=ubuntu:20.04 .
```

### Fedora image

```sh
podman build -f fedora.dockerfile --format docker .
```

By default it builds on top of the latest stable Fedora release (`fedora:latest` on registry.fedoraproject.org).

` --format docker` is necessary for health check support.

To choose another base image/distro, pass `--build-arg base_image=...`:

```sh
podman build -f fedora.dockerfile --format docker --build-arg base_image=registry.fedoraproject.org/fedora:34 .
```
