ARG base_image=ubuntu-22.04

FROM debian:11@sha256:0a78ed641b76252739e28ebbbe8cdbd80dc367fba4502565ca839e5803cfd86e AS debian-11
FROM ubuntu:20.04@sha256:b795f8e0caaaacad9859a9a38fe1c78154f8301fdaf0872eaf1520d66d9c0b98 AS ubuntu-20.04
FROM ubuntu:22.04@sha256:7a57c69fe1e9d5b97c5fe649849e79f2cfc3bf11d10bbd5218b4eb61716aebe6 AS ubuntu-22.04
FROM ubuntu:22.10@sha256:a9a425d086dbb34c1b5b99765596e2a3cc79b33826866c51cd4508d8eb327d2b AS ubuntu-22.10
FROM ubuntu:23.04@sha256:2f18a21d414ad3c0a8eea08fec8f98d730c5c02ddb0d5fef9c60ca72ac53329c AS ubuntu-23.04

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
