ARG base_image=ubuntu-22.04

FROM debian:11@sha256:54d33aaad0bc936a9a40d856764c7bc35c0afaa9cab51f88bb95f6cd8004438d AS debian-11
FROM debian:12@sha256:eaace54a93d7b69c7c52bb8ddf9b3fcba0c106a497bc1fdbb89a6299cf945c63 AS debian-12
FROM ubuntu:20.04@sha256:33a5cc25d22c45900796a1aca487ad7a7cb09f09ea00b779e3b2026b4fc2faba AS ubuntu-20.04
FROM ubuntu:22.04@sha256:9b8dec3bf938bc80fbe758d856e96fdfab5f56c39d44b0cff351e847bb1b01ea AS ubuntu-22.04
FROM ubuntu:23.04@sha256:f1090cfa89ab321a6d670e79652f61593502591f2fc7452fb0b7c6da575729c4 AS ubuntu-23.04

FROM ${base_image}

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        gnome-session gjs dbus-user-session gdm3 gir1.2-vte-2.91 xvfb \
        packagekit gir1.2-packagekitglib-1.0

COPY common debian /

RUN systemctl set-default gnome-session-x11.target && \
    systemctl mask systemd-oomd low-memory-monitor rtkit-daemon udisks2 && \
    useradd -m -U -G users,adm gnomeshell && \
    mkdir -p /var/lib/systemd/linger && \
    touch /var/lib/systemd/linger/gnomeshell && \
    su -l gnomeshell -c ' \
        mkdir -p $HOME/.config/systemd/user/sockets.target.wants/ && \
        ln -s /etc/xdg/systemd/user/dbus-proxy@.socket $HOME/.config/systemd/user/sockets.target.wants/dbus-proxy@1234.socket \
    ' && \
    truncate --size 0 /etc/machine-id && \
    dconf update

# dbus port
EXPOSE 1234
LABEL user-dbus-port=1234

# X11 port
EXPOSE 6099
LABEL x11-port=6099 x11-display-number=99

HEALTHCHECK CMD busctl --watch-bind=true status && systemctl is-system-running --wait

CMD [ "/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
