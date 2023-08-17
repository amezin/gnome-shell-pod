#!/bin/bash

set -e

# https://gitlab.freedesktop.org/xorg/xserver/-/merge_requests/185
# sd_notify() was added to Xorg in 21.1
# But some distros still ship 1.20.* - that's why this "forking" wrapper exists

read -r DISPLAY_NUMBER < <(
    if [ -n "${PIDFILE}" ]; then
        echo "${BASHPID}" >"${PIDFILE}"
    fi

    exec Xvfb "$@" -displayfd 1
)

systemctl --user set-environment "DISPLAY=:${DISPLAY_NUMBER}"
