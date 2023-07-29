ARG base_image=fedora-38

FROM registry.fedoraproject.org/fedora:37@sha256:dc4eaa0cad4fb6b5aa6e83fcc51b18b3cc7711e01d1a4474a35d82d7953dc479 AS fedora-37
FROM registry.fedoraproject.org/fedora:38@sha256:90afa0d40e87d356ed1c715195fdbbf5bb096339d5800f02b2abbfb462e18c88 AS fedora-38
FROM quay.io/centos/centos:stream9@sha256:8ab606dd0bb9ef4877c8b7790c8a35ec5778208f7147b66754a6a1308e88d29d AS centos-9

FROM ${base_image}

RUN dnf update -y && \
    dnf install -y gnome-session-xsession gnome-extensions-app gjs vte291 \
                   xorg-x11-server-Xvfb mesa-dri-drivers \
                   PackageKit PackageKit-glib \
                   --nodocs --setopt install_weak_deps=False && dnf clean all -y

COPY common fedora /

# Start Xvfb via systemd on display :99.
# Add the gnomeshell user with no password.
RUN systemctl enable xvfb@:99.service && \
    systemctl set-default multi-user.target && \
    systemctl --global disable dbus-broker && \
    systemctl --global enable dbus-daemon && \
    systemctl mask systemd-oomd low-memory-monitor rtkit-daemon udisks2 && \
    systemctl --global mask org.gnome.SettingsDaemon.Subscription && \
    adduser -m -U -G users,adm gnomeshell

# dbus port
EXPOSE 1234
LABEL user-dbus-port=1234

# X11 port
EXPOSE 6099
LABEL x11-port=6099 x11-display-number=99

CMD [ "/usr/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
