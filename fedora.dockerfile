ARG base_image=fedora-36

FROM registry.fedoraproject.org/fedora:36@sha256:c4e7506d9487909e2dd53f5ac864e5ce8fb84e0dde60778cbaf3533f6b2cf5ba AS fedora-36
FROM registry.fedoraproject.org/fedora:37@sha256:ecd4b1b115cf713803d423674a20d5ff828a06ba8130864428532dc35a4f216c AS fedora-37
FROM registry.fedoraproject.org/fedora:38@sha256:add2f2878b383c6527a4f692c18f4aca039e7f24f5b24df1a6808f2a95280bbd AS fedora-38
FROM quay.io/centos/centos:stream9@sha256:df58c042d814fad4eed47b12086778d521decf90bf50cc94d01e604fd20a0e9b AS centos-9

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
