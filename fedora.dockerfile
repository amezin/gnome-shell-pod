ARG base_image=fedora-36

FROM registry.fedoraproject.org/fedora:35@sha256:a0ac5d212f0fca2ddb55078b6f3bb31a92e5dc944ba8f4e37e322f38f01bff2d AS fedora-35
FROM registry.fedoraproject.org/fedora:36@sha256:664286544857bcd6365b51d8ee096d91289a8db0ee6e9e41072e021719a511fa AS fedora-36
FROM registry.fedoraproject.org/fedora:37@sha256:ce08a91085403ecbc637eb2a96bd3554d75537871a12a14030b89243501050f2 AS fedora-37

FROM ${base_image}

RUN dnf update -y && \
    dnf install -y gnome-session-xsession gnome-extensions-app gjs vte291 \
                   xorg-x11-server-Xvfb xdotool xautomation mesa-dri-drivers \
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
    systemctl mask systemd-oomd && \
    systemctl --global mask xdg-document-portal gnome-keyring && \
    adduser -m -U -G users,adm gnomeshell

# dbus port
EXPOSE 1234

CMD [ "/usr/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
