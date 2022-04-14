ARG base_image=debian:latest
FROM ${base_image}

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        gnome-session gir1.2-vte-2.91 xsltproc \
        libglib2.0-dev-bin libgtk-3-bin $(apt-cache show libgtk-4-bin >/dev/null && echo -n libgtk-4-bin) \
        xvfb xdotool xautomation \
        sudo make patch jq unzip git npm

COPY etc /etc
COPY debian/etc /etc

# Start Xvfb via systemd on display :99.
# Add the gnomeshell user with no password.
# Unmask required on Fedora 32
RUN systemctl unmask systemd-logind.service console-getty.service getty.target && \
    systemctl disable bluetooth.service && \
    systemctl enable xvfb@:99.service && \
    systemctl set-default multi-user.target && \
    useradd -m -U -G users,adm gnomeshell && \
    echo "gnomeshell     ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Add the scripts.
COPY bin /usr/local/bin

# dbus port
EXPOSE 1234

CMD [ "/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
