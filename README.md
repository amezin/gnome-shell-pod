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
IMAGE="ghcr.io/amezin/gnome-shell-pod/fedora-35:master"
PACKAGE_MOUNTPATH="/home/gnomeshell/.local/share/gnome-shell/extensions/${EXTENSION_UUID}"

POD=$(podman run --rm --cap-add=SYS_NICE,IPC_LOCK,SYS_PTRACE,SETPCAP,NET_RAW,NET_BIND_SERVICE -v "${SOURCE_DIR}:${PACKAGE_MOUNTPATH}:ro" -td "${IMAGE}")
```

### 2. Wait for user systemd and D-Bus to start:

```sh
podman exec --user gnomeshell "${POD}" set-env.sh wait-user-bus.sh
```

### 3. Start GNOME Shell:

```sh
podman exec --user gnomeshell "${POD}" set-env.sh systemctl --user start "gnome-xsession@:99"
```

This command starts X11 GNOME session. It is also possible to start a Wayland
session:

```sh
podman exec --user gnomeshell "${POD}" set-env.sh systemctl --user start "gnome-wayland-nested@:99"
```

It still runs in Xvfb, but in nested mode. Without window manager running on
the "top level", the window has no decorations, and is effectively full screen.

### 4. Wait for GNOME Shell to complete startup:

```sh
podman exec --user gnomeshell "${POD}" set-env.sh wait-dbus-interface.sh -d org.gnome.Shell -o /org/gnome/Shell -i org.gnome.Shell.Extensions
```

`org.gnome.Shell.Extensions` interface is necessary to enable the extension.

`wait-dbus-interface.sh` can be used to wait for any D-Bus interface to become
available. For example, if your extension exports a D-Bus interface, you could
use this script to wait for it.

### 5. Enable the extension:

```sh
gnome-extensions enable "${EXTENSION_UUID}"
```

## Example

See https://github.com/amezin/gnome-shell-extension-ddterm:

- https://github.com/amezin/gnome-shell-extension-ddterm/blob/master/run_test_podman.sh

- https://github.com/amezin/gnome-shell-extension-ddterm/blob/master/.github/workflows/test.yml

## D-Bus

Session D-Bus daemon is listening on TCP port `1234`. To access it from host,
add `--publish`/`--publish-all` option to `podman run` (see `podman` docs).

## Building the image

### Debian/Ubuntu image

```sh
podman build -f debian.dockerfile .
```

By default it builds on top of the latest stable Debian release (`debian:latest` on Docker Hub).

To choose another base image/distro, pass `--build-arg base_image=...`:

```sh
podman build -f debian.dockerfile --build-arg base_image=ubuntu:20.04 .
```

### Fedora image

```sh
podman build -f fedora.dockerfile .
```

By default it builds on top of the latest stable Fedora release (`fedora:latest` on registry.fedoraproject.org).

To choose another base image/distro, pass `--build-arg base_image=...`:

```sh
podman build -f debian.dockerfile --build-arg base_image=registry.fedoraproject.org/fedora:34 .
```
