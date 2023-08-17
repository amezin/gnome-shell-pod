ARG base_image=ubuntu-22.04

FROM debian:11@sha256:1beb7cf458bdfe71b5220cb2069eb45e3fc7eb77a1ccfb169eaebf5f6c4809ab AS debian-11
FROM debian:12@sha256:9008de19fcf0f476fd2e6b43e16c33332afac4e9d7b95d8ae032e5fb4dead37a AS debian-12
FROM ubuntu:20.04@sha256:3246518d9735254519e1b2ff35f95686e4a5011c90c85344c1f38df7bae9dd37 AS ubuntu-20.04
FROM ubuntu:22.04@sha256:56887c5194fddd8db7e36ced1c16b3569d89f74c801dc8a5adbf48236fb34564 AS ubuntu-22.04
FROM ubuntu:22.10@sha256:e322f4808315c387868a9135beeb11435b5b83130a8599fd7d0014452c34f489 AS ubuntu-22.10
FROM ubuntu:23.04@sha256:3787e67b05ccc44d64b821470510a551eea6a2887c8e60379aca0e2fecaff599 AS ubuntu-23.04

FROM ${base_image}

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        gnome-session gjs dbus-user-session gir1.2-vte-2.91 xvfb \
        packagekit gir1.2-packagekitglib-1.0

COPY common /

# Start Xvfb via systemd on display :99.
# Add the gnomeshell user with no password.
RUN systemctl enable xvfb@:99.service && \
    systemctl set-default multi-user.target && \
    systemctl mask systemd-oomd low-memory-monitor rtkit-daemon udisks2 && \
    useradd -m -U -G users,adm gnomeshell && \
    mkdir -p /var/lib/systemd/linger && \
    touch /var/lib/systemd/linger/gnomeshell && \
    su -l gnomeshell -c ' \
        mkdir -p $HOME/.config/systemd/user/sockets.target.wants/ && \
        ln -s /etc/xdg/systemd/user/dbus-proxy@.socket $HOME/.config/systemd/user/sockets.target.wants/dbus-proxy@1234.socket \
    ' && \
    truncate --size 0 /etc/machine-id

# dbus port
EXPOSE 1234
LABEL user-dbus-port=1234

# X11 port
EXPOSE 6099
LABEL x11-port=6099 x11-display-number=99

CMD [ "/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
