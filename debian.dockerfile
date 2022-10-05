ARG base_image=ubuntu-22.04

FROM debian:11@sha256:e538a2f0566efc44db21503277c7312a142f4d0dedc5d2886932b92626104bff AS debian-11
FROM ubuntu:20.04@sha256:e722c7335fdd0ce77044ab5942cb1fbd2b5f60d1f5416acfcdb0814b2baf7898 AS ubuntu-20.04
FROM ubuntu:22.04@sha256:a8fe6fd30333dc60fc5306982a7c51385c2091af1e0ee887166b40a905691fd0 AS ubuntu-22.04

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
