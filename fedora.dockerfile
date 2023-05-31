ARG base_image=fedora-36

FROM registry.fedoraproject.org/fedora:36@sha256:c4e7506d9487909e2dd53f5ac864e5ce8fb84e0dde60778cbaf3533f6b2cf5ba AS fedora-36
FROM registry.fedoraproject.org/fedora:37@sha256:a8d33f7a0695bafdb7dfec845453cc8e7d7a3e47ccc5680af4f18b4450e89300 AS fedora-37
FROM registry.fedoraproject.org/fedora:38@sha256:b14af4b4e7abb04e3dd4d7194d9415cedc6f587b6e446581d4ec110f94f9a75f AS fedora-38
FROM quay.io/centos/centos:stream9@sha256:d075b8cb028de107de53d601512f6f2fc70c8d3c1313959d5925a5386dd1d665 AS centos-9

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
LABEL user-dbus-port=1234

# X11 port
EXPOSE 6099
LABEL x11-port=6099 x11-display-number=99

CMD [ "/usr/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
