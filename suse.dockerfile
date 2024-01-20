FROM registry.opensuse.org/opensuse/tumbleweed:latest@sha256:59a8d47cd3626c90658ca6c216a18f2811edeaa0006ef9311967d2239e89154e

RUN zypper --non-interactive install --no-recommends \
        xorg-x11-server-Xvfb gjs gdm gnome-session-wayland gnome-extensions gtk3-metatheme-adwaita \
        typelib-1_0-Vte-2_91 PackageKit typelib-1_0-PackageKitGlib-1_0 wl-clipboard && zypper clean --all

COPY common suse /

RUN systemctl set-default gnome-session-x11.target && \
    systemctl mask systemd-oomd low-memory-monitor rtkit-daemon udisks2 && \
    useradd -m -U -G users gnomeshell && \
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
