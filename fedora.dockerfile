ARG base_image=fedora-38

FROM registry.fedoraproject.org/fedora:37@sha256:7038eb8eca0aae01c15836eb92032332672c022d3e192977f8a39155803fd52a AS fedora-37
FROM registry.fedoraproject.org/fedora:38@sha256:242d1f52519f56bb9cee9658c39a8d9978e927260330ce92b830ea2f9460d750 AS fedora-38
FROM registry.fedoraproject.org/fedora:39@sha256:2eebaade7f324f1c22c4b50f18ae8c13ce6ddf31d43c53f2584133fa42884324 AS fedora-39
FROM quay.io/centos/centos:stream9@sha256:c1768e42666a0b8953636b7d2636f0156814bc930dbd722a7da8d3985ae3da8a AS centos-9

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
