ARG base_image=fedora-36

FROM registry.fedoraproject.org/fedora:35@sha256:e1ed8fdfa563a9d5e0adc096fcb4f5da0cc1c788dfa9c51bbc4d561fa69dae39 AS fedora-35
FROM registry.fedoraproject.org/fedora:36@sha256:e9b9d4ae36aa1ee0ee7b4b7fc6f470e24e3b473ac2cfb9c1abde2b8fb2500b99 AS fedora-36

FROM ${base_image}

RUN dnf update -y && \
    dnf install -y gnome-session-xsession gnome-extensions-app gjs vte291 \
                   xorg-x11-server-Xvfb xdotool xautomation mesa-dri-drivers \
                   --nodocs --setopt install_weak_deps=False && dnf clean all -y

COPY etc /etc
COPY fedora/etc /etc

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

# Add the scripts.
COPY bin /usr/local/bin

# dbus port
EXPOSE 1234

CMD [ "/usr/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]