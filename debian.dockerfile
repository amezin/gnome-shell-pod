ARG base_image=ubuntu-22.04

FROM debian:11@sha256:43ef0c6c3585d5b406caa7a0f232ff5a19c1402aeb415f68bcd1cf9d10180af8 AS debian-11
FROM ubuntu:20.04@sha256:bffb6799d706144f263f4b91e1226745ffb5643ea0ea89c2f709208e8d70c999 AS ubuntu-20.04
FROM ubuntu:22.04@sha256:c985bc3f77946b8e92c9a3648c6f31751a7dd972e06604785e47303f4ad47c4c AS ubuntu-22.04
FROM ubuntu:22.10@sha256:a630e0fd2ea08f74080cddba4063fb9a840526697c551f52a183c674e3130179 AS ubuntu-22.10

FROM ${base_image}

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        gnome-session gjs dbus-user-session gir1.2-vte-2.91 xvfb \
        packagekit gir1.2-packagekitglib-1.0

COPY common debian /

# Start Xvfb via systemd on display :99.
# Add the gnomeshell user with no password.
# Unmask required on Fedora 32
RUN systemctl unmask systemd-logind.service console-getty.service getty.target && \
    systemctl enable xvfb@:99.service && \
    systemctl set-default multi-user.target && \
    systemctl mask systemd-oomd && \
    systemctl --global mask xdg-document-portal gnome-keyring && \
    useradd -m -U -G users,adm gnomeshell

# dbus port
EXPOSE 1234

# X11 port
EXPOSE 6099

CMD [ "/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
