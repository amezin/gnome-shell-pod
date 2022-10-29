ARG base_image=fedora-36

FROM registry.fedoraproject.org/fedora:35@sha256:76fad5d5ade3a3f27530b82be513937f9c39aa82e6e3eeb1ad0d171753ade1ac AS fedora-35
FROM registry.fedoraproject.org/fedora:36@sha256:e9b9d4ae36aa1ee0ee7b4b7fc6f470e24e3b473ac2cfb9c1abde2b8fb2500b99 AS fedora-36
FROM registry.fedoraproject.org/fedora:37@sha256:bb0155d740712035427198878748574131c6bba40df932ee87f80ea089fae8dc AS fedora-37

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
