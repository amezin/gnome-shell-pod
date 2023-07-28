ARG base_image=ubuntu-22.04

FROM debian:11@sha256:630454da4c59041a2bca987a0d54c68962f1d6ea37a3641bd61db42b753234f2 AS debian-11
FROM debian:12@sha256:f2150eba68619015058b26d50e47f9fba81213d1cb81633be7928c830f72d180 AS debian-12
FROM ubuntu:20.04@sha256:8c38f4ea0b178a98e4f9f831b29b7966d6654414c1dc008591c6ec77de3bf2c9 AS ubuntu-20.04
FROM ubuntu:22.04@sha256:b060fffe8e1561c9c3e6dea6db487b900100fc26830b9ea2ec966c151ab4c020 AS ubuntu-22.04
FROM ubuntu:22.10@sha256:e322f4808315c387868a9135beeb11435b5b83130a8599fd7d0014452c34f489 AS ubuntu-22.10
FROM ubuntu:23.04@sha256:09f035f46361d193ded647342903b413d57d05cc06acff8285f9dda9f2d269d5 AS ubuntu-23.04

FROM ${base_image}

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        gnome-session gjs dbus-user-session gir1.2-vte-2.91 xvfb \
        packagekit gir1.2-packagekitglib-1.0

COPY common debian /

# Start Xvfb via systemd on display :99.
# Add the gnomeshell user with no password.
RUN systemctl enable xvfb@:99.service && \
    systemctl set-default multi-user.target && \
    systemctl mask systemd-oomd low-memory-monitor rtkit-daemon udisks2 && \
    useradd -m -U -G users,adm gnomeshell

# dbus port
EXPOSE 1234
LABEL user-dbus-port=1234

# X11 port
EXPOSE 6099
LABEL x11-port=6099 x11-display-number=99

CMD [ "/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
