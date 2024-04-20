ARG base_image=fedora-38

FROM registry.fedoraproject.org/fedora:38@sha256:6349d2df6b4322c5690df1bb7743c45c356e20471dda69f27218cd9ba4a6c3c7 AS fedora-38
FROM registry.fedoraproject.org/fedora:39@sha256:3acfe736676624edd56d793a47207caf6febc06dff2d1cf9aa974ddde83ee336 AS fedora-39
FROM registry.fedoraproject.org/fedora:40@sha256:ede1e07259c695856d1fe4ba9978c6a9e26273ae2989968fd0d730d8e91822b5 AS fedora-40
FROM quay.io/centos/centos:stream9@sha256:c89fc32d7a368acb4c3bae3fe9180309d323bedef187ecf2952a8ff4eae4e12b AS centos-9

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
