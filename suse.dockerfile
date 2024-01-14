FROM registry.opensuse.org/opensuse/tumbleweed:latest@sha256:69bac4f06b1812221fd1cc61b4236ad20e7f32309bfe524e1f3896867786c228

RUN zypper --non-interactive install --no-recommends \
        xorg-x11-server-Xvfb gjs gdm gnome-session-wayland gnome-extensions gtk3-metatheme-adwaita \
        typelib-1_0-Vte-2_91 PackageKit typelib-1_0-PackageKitGlib-1_0 wl-clipboard

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
