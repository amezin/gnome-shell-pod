ARG base_image=ubuntu-22.04

FROM debian:11@sha256:1e5f2d70c9441c971607727f56d0776fb9eecf23cd37b595b26db7a974b2301d AS debian-11
FROM debian:12@sha256:e7072ef5bbeaca98db3056a7d944d5dfb7a44d47770d10d54ee3f5a61144f049 AS debian-12
FROM ubuntu:20.04@sha256:b795f8e0caaaacad9859a9a38fe1c78154f8301fdaf0872eaf1520d66d9c0b98 AS ubuntu-20.04
FROM ubuntu:22.04@sha256:2fdb1cf4995abb74c035e5f520c0f3a46f12b3377a59e86ecca66d8606ad64f9 AS ubuntu-22.04
FROM ubuntu:22.10@sha256:a9a425d086dbb34c1b5b99765596e2a3cc79b33826866c51cd4508d8eb327d2b AS ubuntu-22.10
FROM ubuntu:23.04@sha256:5ed6262a1edb954cae006b966ca70468e982285aa57419b4d2b221a5e11dd881 AS ubuntu-23.04

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
