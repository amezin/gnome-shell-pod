ARG base_image=debian:latest
FROM ${base_image}

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        gnome-session gjs dbus-user-session gir1.2-vte-2.91 xvfb xdotool xautomation

COPY etc /etc
COPY debian/etc /etc

# Start Xvfb via systemd on display :99.
# Add the gnomeshell user with no password.
# Unmask required on Fedora 32
RUN systemctl unmask systemd-logind.service console-getty.service getty.target && \
    systemctl enable xvfb@:99.service && \
    systemctl set-default multi-user.target && \
    systemctl mask systemd-oomd && \
    systemctl --global mask xdg-document-portal gnome-keyring && \
    useradd -m -U -G users,adm gnomeshell

# Add the scripts.
COPY bin /usr/local/bin

# dbus port
EXPOSE 1234

CMD [ "/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
