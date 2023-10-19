ARG base_image=fedora-38

FROM registry.fedoraproject.org/fedora:37@sha256:f2dd052b892fbc82a8624e71cbf71bab6e202a7da48f7fc14febe611f9b022b6 AS fedora-37
FROM registry.fedoraproject.org/fedora:38@sha256:d643707ffb780448c26dd5164edba3291aa39dbd790d06fbf779511bbe32cba9 AS fedora-38
FROM registry.fedoraproject.org/fedora:39@sha256:a4281b2eb89adb8d99d08c2d7fb5d7c89e33c2ecd7b5daa086061a6de97811a4 AS fedora-39
FROM quay.io/centos/centos:stream9@sha256:aeca8aee6df1e62c25f306396dc6631520dc350fe90d48cf30f45272ffeb2c61 AS centos-9

FROM ${base_image}

RUN dnf update -y && \
    dnf install -y gnome-session-xsession gnome-extensions-app gjs gdm vte291 \
                   xorg-x11-server-Xvfb mesa-dri-drivers \
                   PackageKit PackageKit-glib \
                   --nodocs --setopt install_weak_deps=False && dnf clean all -y

COPY common /

RUN systemctl set-default gnome-session-x11.target && \
    systemctl --global disable dbus-broker && \
    systemctl --global enable dbus-daemon && \
    systemctl mask systemd-oomd low-memory-monitor rtkit-daemon udisks2 && \
    systemctl --global mask org.gnome.SettingsDaemon.Subscription && \
    adduser -m -U -G users,adm gnomeshell && \
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

CMD [ "/usr/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
