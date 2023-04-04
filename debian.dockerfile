ARG base_image=ubuntu-22.04

FROM debian:11@sha256:7b991788987ad860810df60927e1adbaf8e156520177bd4db82409f81dd3b721 AS debian-11
FROM ubuntu:20.04@sha256:b39db7fc56971aac21dee02187e898db759c4f26b9b27b1d80b6ad32ff330c76 AS ubuntu-20.04
FROM ubuntu:22.04@sha256:7a57c69fe1e9d5b97c5fe649849e79f2cfc3bf11d10bbd5218b4eb61716aebe6 AS ubuntu-22.04
FROM ubuntu:22.10@sha256:a82eebb42083a134e009a6b81a7e5d2eecc37112fa8ae40642bd3c5153b7e4f0 AS ubuntu-22.10

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
LABEL user-dbus-port=1234

# X11 port
EXPOSE 6099
LABEL x11-port=6099 x11-display-number=99

CMD [ "/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
