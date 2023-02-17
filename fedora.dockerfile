ARG base_image=fedora-36

FROM registry.fedoraproject.org/fedora:36@sha256:e04e1f5b791c109a33f95512bcf8c2a99b33b7e2c6da029b6a4eaccb1eea3025 AS fedora-36
FROM registry.fedoraproject.org/fedora:37@sha256:b0c61163ff03105c5cce455b01f962e32d79895417bb153894cfa4e135bdb46a AS fedora-37
FROM quay.io/centos/centos:stream9@sha256:3cb41b4ae0a25539c7d588fb7c4ce716aafbf8682de42075326d877281845433 AS centos-9

FROM ${base_image}

RUN dnf update -y && \
    dnf install -y gnome-session-xsession gnome-extensions-app gjs vte291 \
                   xorg-x11-server-Xvfb mesa-dri-drivers \
                   PackageKit PackageKit-glib \
                   --nodocs --setopt install_weak_deps=False && dnf clean all -y

COPY common fedora /

# Start Xvfb via systemd on display :99.
# Add the gnomeshell user with no password.
# Unmask required on Fedora 32
RUN systemctl unmask systemd-logind.service console-getty.service getty.target && \
    systemctl enable xvfb@:99.service && \
    systemctl set-default multi-user.target && \
    systemctl --global disable dbus-broker && \
    systemctl --global enable dbus-daemon && \
    systemctl mask systemd-oomd low-memory-monitor && \
    systemctl --global mask xdg-document-portal gnome-keyring org.gnome.SettingsDaemon.Subscription && \
    adduser -m -U -G users,adm gnomeshell

# dbus port
EXPOSE 1234

# X11 port
EXPOSE 6099

CMD [ "/usr/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
