ARG base_image=ubuntu-24.04

FROM docker.io/library/debian:12@sha256:aadf411dc9ed5199bc7dab48b3e6ce18f8bbee4f170127f5ff1b75cd8035eb36 AS debian-12
FROM docker.io/library/debian:trixie@sha256:0c75aed52e3a564e27c3aaba51b0a7e59ac21dd09abcb25f2fe0b9b37c8f7e01 AS debian-13
FROM docker.io/library/ubuntu:24.04@sha256:2e863c44b718727c860746568e1d54afd13b2fa71b160f5cd9058fc436217b30 AS ubuntu-24.04

FROM ${base_image}

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        gnome-session \
        gjs \
        dbus-user-session \
        gdm3 \
        gir1.2-vte-2.91 \
        gir1.2-vte-3.91 \
        xvfb \
        packagekit \
        gir1.2-packagekitglib-1.0 \
        wl-clipboard \
        gir1.2-handy-1

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
