#!/usr/bin/env bash

if [[ $# != 2 ]]; then
    echo "Usage: $0 image-name session-name" >&2
    exit 1
fi

function shutdown {
    podman exec "$CID" systemctl list-units --failed || true
    podman exec --user gnomeshell "$CID" set-env.sh systemctl --user list-units --failed || true
    podman stop --cidfile="$CIDFILE"

    rm -rf "$WORKDIR"
}

set -ex

WORKDIR="$(mktemp -d)"
CIDFILE="$WORKDIR/cid"
CAPS="SYS_NICE,SYS_PTRACE,SETPCAP,NET_RAW,NET_BIND_SERVICE,DAC_READ_SEARCH"

podman run --rm -Ptd --cap-add="$CAPS" --cidfile="$CIDFILE" "$1"

CID="$(<"$CIDFILE")"

trap shutdown EXIT

podman attach --no-stdin --sig-proxy=false "$CID" &
podman exec --user gnomeshell "$CID" set-env.sh wait-user-bus.sh

DBUS_ENDPOINT="$(podman port "$CID" 1234)"
DBUS_ADDRESS="tcp:host=${DBUS_ENDPOINT%%:*},port=${DBUS_ENDPOINT#*:}"
dbus-send --bus="$DBUS_ADDRESS" --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.Peer.Ping

podman exec --user gnomeshell "$CID" set-env.sh systemctl --user start "$2@:99"
podman exec --user gnomeshell "$CID" set-env.sh wait-dbus-interface.sh -d org.gnome.Shell -o /org/gnome/Shell -i org.gnome.Shell.Extensions

dbus-send --bus="$DBUS_ADDRESS" --print-reply --dest=org.gnome.Shell /org/gnome/Shell org.gnome.Shell.Extensions.ListExtensions

podman exec --user gnomeshell "$CID" set-env.sh systemctl --user is-system-running --wait

sleep 15

podman exec "$CID" systemctl is-system-running --wait
podman exec --user gnomeshell "$CID" set-env.sh systemctl --user is-system-running --wait

X11_ENDPOINT="$(podman port "$CID" 6099)"
DISPLAY="${X11_ENDPOINT%%:*}:$(( ${X11_ENDPOINT#*:} - 6000 ))" xdpyinfo
