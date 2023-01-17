FROM archlinux:latest@sha256:e7fb3b7f2840a68d9dd07ad5741dd9a773fde63d870c568978dba329d01d172b

RUN pacman -Sy --noconfirm gnome-shell vte3 xorg-server-xvfb xorg-xinit mesa packagekit && \
    pacman -Rdd --noconfirm rtkit && \
    pacman -Scc --noconfirm

COPY common archlinux /

# Start Xvfb via systemd on display :99.
# Add the gnomeshell user with no password.
RUN systemctl unmask systemd-logind.service console-getty.service getty.target && \
    systemctl enable xvfb@:99.service && \
    systemctl set-default multi-user.target && \
    systemctl mask systemd-oomd && \
    systemctl --global mask xdg-document-portal gnome-keyring && \
    useradd -m -U -G users,adm gnomeshell && \
    systemd-machine-id-setup

# dbus port
EXPOSE 1234

# X11 port
EXPOSE 6099

CMD [ "/usr/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
