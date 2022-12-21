ARG base_image=fedora-36

FROM registry.fedoraproject.org/fedora:36@sha256:664286544857bcd6365b51d8ee096d91289a8db0ee6e9e41072e021719a511fa AS fedora-36
FROM registry.fedoraproject.org/fedora:37@sha256:ce08a91085403ecbc637eb2a96bd3554d75537871a12a14030b89243501050f2 AS fedora-37
FROM quay.io/centos/centos:stream9@sha256:0a7e70a92900160c24857fc2d5d6f85c0fcc06fda352f65d4fd331427c58f6cc AS centos-9

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
