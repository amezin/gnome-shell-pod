#!/usr/bin/env bash

if [[ $# != 2 ]]; then
    echo "Usage: $0 image-name session-name" >&2
    exit 1
fi

function shutdown {
    podman exec "$CID" systemctl list-units --failed || true
    podman exec --user gnomeshell "$CID" set-env.sh systemctl --user list-units --failed || true
    podman rm -f "$CID"
}

set -ex

CAPS="SYS_NICE,SYS_PTRACE,SETPCAP,NET_RAW,NET_BIND_SERVICE,DAC_READ_SEARCH"
CID="$(podman create -Pt --cap-add="$CAPS" "$1")"

trap shutdown EXIT

DBUS_CONTAINER_PORT="$(podman container inspect --format='{{index .Config.Labels "user-dbus-port"}}' "$CID")"
X11_CONTAINER_PORT="$(podman container inspect --format='{{index .Config.Labels "x11-port"}}' "$CID")"

podman start --attach --sig-proxy=false "$CID" &
podman wait --condition=running "$CID"
podman exec --user gnomeshell "$CID" set-env.sh wait-user-bus.sh

DBUS_ENDPOINT="$(podman port "$CID" "$DBUS_CONTAINER_PORT")"
DBUS_ADDRESS="tcp:host=${DBUS_ENDPOINT%%:*},port=${DBUS_ENDPOINT#*:}"
dbus-send --bus="$DBUS_ADDRESS" --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.Peer.Ping

podman exec --user gnomeshell "$CID" set-env.sh systemctl --user start "$2@:99"
podman exec --user gnomeshell "$CID" set-env.sh wait-dbus-interface.sh -d org.gnome.Shell -o /org/gnome/Shell -i org.gnome.Shell.Extensions

dbus-send --bus="$DBUS_ADDRESS" --print-reply --dest=org.gnome.Shell /org/gnome/Shell org.gnome.Shell.Extensions.ListExtensions

podman exec --user gnomeshell "$CID" set-env.sh systemctl --user is-system-running --wait

sleep 15

podman exec "$CID" systemctl is-system-running --wait
podman exec --user gnomeshell "$CID" set-env.sh systemctl --user is-system-running --wait

X11_ENDPOINT="$(podman port "$CID" "$X11_CONTAINER_PORT")"
DISPLAY="${X11_ENDPOINT%%:*}:$(( ${X11_ENDPOINT#*:} - 6000 ))" xdpyinfo
