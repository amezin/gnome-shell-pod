#!/usr/bin/env bash

if [[ $# != 2 ]]; then
    echo "Usage: $0 image-name session-name" >&2
    exit 1
fi

SCRIPT_DIR=$(CDPATH="" cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

function shutdown {
    podman exec "$CID" systemctl list-units --failed || true
    podman exec --user gnomeshell "$CID" set-env.sh systemctl --user list-units --failed || true
    podman rm -f "$CID"
}

set -ex

CAPS="SYS_ADMIN,SYS_NICE,SYS_PTRACE,SETPCAP,NET_RAW,NET_BIND_SERVICE,DAC_READ_SEARCH,IPC_LOCK"
CID="$(podman create -Pt --cap-add="$CAPS" "$1" /sbin/init systemd.unified_cgroup_hierarchy=0 "systemd.unit=$2.target")"

trap shutdown EXIT

DBUS_CONTAINER_PORT="$(podman container inspect --format='{{index .Config.Labels "user-dbus-port"}}' "$CID")"
X11_CONTAINER_PORT="$(podman container inspect --format='{{index .Config.Labels "x11-port"}}' "$CID")"

podman start --attach --sig-proxy=false "$CID" &
podman wait --condition=running "$CID"
podman exec "$CID" busctl --watch-bind=true status
podman exec "$CID" systemctl is-system-running --wait

DBUS_ENDPOINT="$(podman port "$CID" "$DBUS_CONTAINER_PORT")"
DBUS_ADDRESS="tcp:host=${DBUS_ENDPOINT%%:*},port=${DBUS_ENDPOINT#*:}"
dbus-send --bus="$DBUS_ADDRESS" --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.Peer.Ping
dbus-send --bus="$DBUS_ADDRESS" --print-reply --dest=org.gnome.Shell /org/gnome/Shell org.gnome.Shell.Extensions.ListExtensions

podman exec --user gnomeshell "$CID" set-env.sh systemctl --user is-system-running --wait

USER_ID="$(podman exec --user gnomeshell "$CID" id -u)"
podman cp "$SCRIPT_DIR/gnome.shell.pod.test.service" "$CID:/run/user/$USER_ID/dbus-1/services/"
podman cp "$SCRIPT_DIR/gtk3-app.js" "$CID:/usr/local/bin/"

dbus-send --bus="$DBUS_ADDRESS" --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.ReloadConfig
dbus-send --bus="$DBUS_ADDRESS" --print-reply --dest=gnome.shell.pod.test /gnome/shell/pod/test gnome.shell.pod.test.Test.TestMethod

sleep 15

podman exec "$CID" systemctl is-system-running --wait
podman exec --user gnomeshell "$CID" set-env.sh systemctl --user is-system-running --wait

X11_ENDPOINT="$(podman port "$CID" "$X11_CONTAINER_PORT")"
export DISPLAY="${X11_ENDPOINT%%:*}:$(( ${X11_ENDPOINT#*:} - 6000 ))"

xdpyinfo
import -window root "$SCRIPT_DIR/screenshot.png"
