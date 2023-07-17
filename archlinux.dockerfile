FROM archlinux:latest@sha256:cf219c9214e840f642076be8eac01509e83fd2ccf540d3f416cd2384c7ebc479

RUN pacman -Syu --noconfirm gnome-shell vte3 xorg-server-xvfb xorg-xinit mesa packagekit && \
    pacman -Scc --noconfirm

COPY common archlinux /

# Start Xvfb via systemd on display :99.
# Add the gnomeshell user with no password.
RUN systemctl enable xvfb@:99.service && \
    systemctl set-default multi-user.target && \
    systemctl mask systemd-oomd low-memory-monitor rtkit-daemon udisks2 && \
    useradd -m -U -G users,adm gnomeshell && \
    systemd-machine-id-setup

# dbus port
EXPOSE 1234
LABEL user-dbus-port=1234

# X11 port
EXPOSE 6099
LABEL x11-port=6099 x11-display-number=99

CMD [ "/usr/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
