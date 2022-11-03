ARG base_image=fedora-36

FROM registry.fedoraproject.org/fedora:35@sha256:76fad5d5ade3a3f27530b82be513937f9c39aa82e6e3eeb1ad0d171753ade1ac AS fedora-35
FROM registry.fedoraproject.org/fedora:36@sha256:7d36dae8e7a197a561818356374034d8efab31f84083d852632cb8efad1f46e6 AS fedora-36
FROM registry.fedoraproject.org/fedora:37@sha256:0fcdbbc867905c096642c2df1828f3a9e1f80618e54f909b1b5e061b33403593 AS fedora-37

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
