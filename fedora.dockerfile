ARG base_image=fedora-38

FROM registry.fedoraproject.org/fedora:37@sha256:02abb391e65619a9e8fb1c1d43cfb6a27c1b9d164ddd01c9364c2a53c931c2a5 AS fedora-37
FROM registry.fedoraproject.org/fedora:38@sha256:a9c8f0795d5e64ac8e93afa5a1aa2c4e54cfbee6def832f7bf0a85a683dd1097 AS fedora-38
FROM registry.fedoraproject.org/fedora:39@sha256:e3a6087f62f288571db14defb7e0e10ad7fe6f973f567b0488d3aac5e927035a AS fedora-39
FROM quay.io/centos/centos:stream9@sha256:8845d412fc1bfcd06a0f8615dcd53acf8f8895af653e40fd95625be6b24c370b AS centos-9

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
