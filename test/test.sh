#!/bin/bash

if [[ $# != 2 ]]; then
    echo "Usage: $0 image-name session-name" >&2
    exit 1
fi

function shutdown {
    podman exec "${POD}" systemctl list-units --failed || true
    podman exec --user gnomeshell "${POD}" set-env.sh systemctl --user list-units --failed || true
    podman kill "${POD}"
}

set -ex

POD=$(podman run --rm -Ptd --publish=6099:6099 --cap-add=SYS_NICE,SYS_PTRACE,SETPCAP,NET_RAW,NET_BIND_SERVICE,DAC_READ_SEARCH "$1")

trap shutdown EXIT

podman attach --no-stdin --sig-proxy=false "${POD}" &
podman exec --user gnomeshell "${POD}" set-env.sh wait-user-bus.sh

DBUS_PORT=$(podman inspect --format '{{(index (index .NetworkSettings.Ports "1234/tcp") 0).HostPort}}' "${POD}")
dbus-send --bus=tcp:host=localhost,port=$DBUS_PORT --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.Peer.Ping

podman exec --user gnomeshell "${POD}" set-env.sh systemctl --user start "$2@:99"
podman exec --user gnomeshell "${POD}" set-env.sh wait-dbus-interface.sh -d org.gnome.Shell -o /org/gnome/Shell -i org.gnome.Shell.Extensions

dbus-send --bus=tcp:host=localhost,port=$DBUS_PORT --print-reply --dest=org.gnome.Shell /org/gnome/Shell org.gnome.Shell.Extensions.ListExtensions

podman exec --user gnomeshell "${POD}" set-env.sh systemctl --user is-system-running --wait

sleep 15

podman exec "${POD}" systemctl is-system-running --wait
podman exec --user gnomeshell "${POD}" set-env.sh systemctl --user is-system-running --wait

DISPLAY=127.0.0.1:99 xdpyinfo
