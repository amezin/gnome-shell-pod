ARG base_image=fedora-36

FROM registry.fedoraproject.org/fedora:36@sha256:c71f1631979975f24ac537a585b6522ff7af364269c4a55d1403df0e3b02e6a0 AS fedora-36
FROM registry.fedoraproject.org/fedora:37@sha256:d61102cd2dfcb5ac29f752554c8738631245acefb02cae741562349a471fc4d3 AS fedora-37
FROM registry.fedoraproject.org/fedora:38@sha256:f20828fb97c99ce6a169fc9aa16242201da1e626123bb8df8921098862e2767f AS fedora-38
FROM quay.io/centos/centos:stream9@sha256:0e94cf0a9eb11c8945e710b634bcc0eb314497d0d435c78e8d1bfdff52cdabd8 AS centos-9

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
