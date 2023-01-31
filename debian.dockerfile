ARG base_image=ubuntu-22.04

FROM debian:11@sha256:534da5794e770279c889daa891f46f5a530b0c5de8bfbc5e40394a0164d9fa87 AS debian-11
FROM ubuntu:20.04@sha256:d5d4814ffb155d588f10ec8926d9e1cd09b6d41a3110d2f42959e2fc37f6d0b4 AS ubuntu-20.04
FROM ubuntu:22.04@sha256:eecba05a9ccbc219cb0f0dd280034c6ee1aab0b00b458e680f9c4efc6ca3feda AS ubuntu-22.04
FROM ubuntu:22.10@sha256:a062bfdb0c233a5a7c4758c028ef6a8f4981b78008606e23f47143ca0bfb483d AS ubuntu-22.10

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
