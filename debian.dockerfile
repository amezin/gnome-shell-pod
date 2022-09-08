ARG base_image=ubuntu-22.04

FROM debian:11@sha256:d52921d97310d0bd48dab928548ef539d5c88c743165754c57cfad003031386c AS debian-11
FROM ubuntu:20.04@sha256:a06ae92523384c2cd182dcfe7f8b2bf09075062e937d5653d7d0db0375ad2221 AS ubuntu-20.04
FROM ubuntu:22.04@sha256:42ba2dfce475de1113d55602d40af18415897167d47c2045ec7b6d9746ff148f AS ubuntu-22.04

FROM ${base_image}

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        gnome-session gjs dbus-user-session gir1.2-vte-2.91 xvfb xdotool xautomation

COPY etc /etc
COPY debian/etc /etc

# Start Xvfb via systemd on display :99.
# Add the gnomeshell user with no password.
# Unmask required on Fedora 32
RUN systemctl unmask systemd-logind.service console-getty.service getty.target && \
    systemctl enable xvfb@:99.service && \
    systemctl set-default multi-user.target && \
    systemctl mask systemd-oomd && \
    systemctl --global mask xdg-document-portal gnome-keyring && \
    useradd -m -U -G users,adm gnomeshell

# Add the scripts.
COPY bin /usr/local/bin

# dbus port
EXPOSE 1234

CMD [ "/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
