#!/bin/bash

set -ex

busctl --system --watch-bind=true status >/dev/null

# systemctl is-system-running --wait hangs on Arch Linux
timeout 10s systemctl is-system-running --wait || systemctl is-system-running --wait

while ! busctl --user --watch-bind=true status >/dev/null; do
    sleep 0.1
done
