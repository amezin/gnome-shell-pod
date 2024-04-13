ARG base_image=fedora-38

FROM registry.fedoraproject.org/fedora:38@sha256:6349d2df6b4322c5690df1bb7743c45c356e20471dda69f27218cd9ba4a6c3c7 AS fedora-38
FROM registry.fedoraproject.org/fedora:39@sha256:0a06efb1c2507497a1cd864f7aaf701712dde8cf3be726c910f19d8e1789d49b AS fedora-39
FROM registry.fedoraproject.org/fedora:40@sha256:cf3812a0e26696ebdf89ed2c536b01c91d7b90bcde37f23a8c1f82cf1926bf70 AS fedora-40
FROM quay.io/centos/centos:stream9@sha256:2fa98912f5964b54df6d3cec50874bf56abc98f13077f710b8ea9dc1b41bfeb5 AS centos-9

FROM ${base_image}

RUN if grep -i centos /etc/os-release; then dnf install -y epel-release --nodocs --setopt install_weak_deps=False; fi && \
    dnf install -y gnome-session-xsession gnome-extensions-app gjs gdm vte291 \
                   xorg-x11-server-Xvfb mesa-dri-drivers wl-clipboard \
                   PackageKit PackageKit-glib libhandy \
                   --nodocs --setopt install_weak_deps=False && dnf clean all -y

COPY common /

RUN systemctl set-default gnome-session-x11.target && \
    systemctl --global disable dbus-broker && \
    systemctl --global enable dbus-daemon && \
    systemctl mask systemd-oomd low-memory-monitor rtkit-daemon udisks2 && \
    systemctl --global mask org.gnome.SettingsDaemon.Subscription && \
    adduser -m -U -G users,adm gnomeshell && \
    mkdir -p /var/lib/systemd/linger && \
    touch /var/lib/systemd/linger/gnomeshell && \
    su -l gnomeshell -c ' \
        mkdir -p $HOME/.config/systemd/user/sockets.target.wants/ && \
        ln -s /etc/xdg/systemd/user/dbus-proxy@.socket $HOME/.config/systemd/user/sockets.target.wants/dbus-proxy@1234.socket \
    ' && \
    truncate --size 0 /etc/machine-id && \
    dconf update

# dbus port
EXPOSE 1234
LABEL user-dbus-port=1234

# X11 port
EXPOSE 6099
LABEL x11-port=6099 x11-display-number=99

HEALTHCHECK CMD busctl --watch-bind=true status && systemctl is-system-running --wait

CMD [ "/usr/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
