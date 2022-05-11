ARG base_image=registry.fedoraproject.org/fedora:latest
FROM ${base_image}

RUN dnf update -y && \
    dnf install -y gnome-session-xsession gnome-extensions-app vte291 \
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
    systemctl mask upower systemd-oomd && \
    systemctl --global mask xdg-document-portal && \
    adduser -m -U -G users,adm gnomeshell

# Add the scripts.
COPY bin /usr/local/bin

# dbus port
EXPOSE 1234

CMD [ "/usr/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
