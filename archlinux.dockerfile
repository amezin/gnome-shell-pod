FROM archlinux:latest@sha256:7c0c89e6ecb7d815ac03bd3318f8974e8f30b9be321dbaf598e6f6aed8abd245

RUN pacman -Syu --noconfirm gnome-shell vte3 xorg-server-xvfb xorg-xinit mesa packagekit && \
    pacman -Scc --noconfirm

COPY common archlinux /

# Start Xvfb via systemd on display :99.
# Add the gnomeshell user with no password.
RUN systemctl unmask systemd-logind.service console-getty.service getty.target && \
    systemctl enable xvfb@:99.service && \
    systemctl set-default multi-user.target && \
    systemctl mask systemd-oomd rtkit-daemon && \
    systemctl --global mask xdg-document-portal gnome-keyring && \
    useradd -m -U -G users,adm gnomeshell && \
    systemd-machine-id-setup

# dbus port
EXPOSE 1234
LABEL user-dbus-port=1234

# X11 port
EXPOSE 6099
LABEL x11-port=6099 x11-display-number=99

CMD [ "/usr/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
