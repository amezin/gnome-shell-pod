ARG base_image=ubuntu-22.04

FROM debian:11@sha256:3066ef83131c678999ce82e8473e8d017345a30f5573ad3e44f62e5c9c46442b AS debian-11
FROM ubuntu:20.04@sha256:b25ef49a40b7797937d0d23eca3b0a41701af6757afca23d504d50826f0b37ce AS ubuntu-20.04
FROM ubuntu:22.04@sha256:817cfe4672284dcbfee885b1a66094fd907630d610cab329114d036716be49ba AS ubuntu-22.04
FROM ubuntu:22.10@sha256:edc5125bd9443ab5d5c92096cf0e481f5e8cb12db9f5461ab1ab7a936c7f7d30 AS ubuntu-22.10

FROM ${base_image}

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        gnome-session gjs dbus-user-session gir1.2-vte-2.91 xvfb xdotool xautomation

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

CMD [ "/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
