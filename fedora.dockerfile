ARG base_image=fedora-38

FROM registry.fedoraproject.org/fedora:37@sha256:c606bb3f15386cd6746d1a942fe39ac02980659798be4c50a5c3ff39f9d89362 AS fedora-37
FROM registry.fedoraproject.org/fedora:38@sha256:a2c59ce2b1b10f290132b4190b6f7ba77e7e9eb705ec4aee043e4bf2b25c069c AS fedora-38
FROM quay.io/centos/centos:stream9@sha256:11e36a49e2936c28eca834428657da8d95e804ed898f4ef8fbfdf171a878e5db AS centos-9

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
