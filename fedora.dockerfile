ARG base_image=fedora-36

FROM registry.fedoraproject.org/fedora:36@sha256:9f348317351a236256c9818a1ccdbb4a6d45da4eec221956b50ef1b0445ba091 AS fedora-36
FROM registry.fedoraproject.org/fedora:37@sha256:176454f0e89d7bda8b8b577bfd855f5cb3854234d781855baef82cb057b0529e AS fedora-37
FROM quay.io/centos/centos:stream9@sha256:3332c6692307ba0bdd916c8681a9a7184ca7630de3706aef3476d4ceb286531f AS centos-9

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
