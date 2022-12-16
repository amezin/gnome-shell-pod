ARG base_image=ubuntu-22.04

FROM debian:11@sha256:a288aa7ad0e4d443e86843972c25a02f99e9ad6ee589dd764895b2c3f5a8340b AS debian-11
FROM ubuntu:20.04@sha256:8eb87f3d6c9f2feee114ff0eff93ea9dfd20b294df0a0353bd6a4abf403336fe AS ubuntu-20.04
FROM ubuntu:22.04@sha256:965fbcae990b0467ed5657caceaec165018ef44a4d2d46c7cdea80a9dff0d1ea AS ubuntu-22.04
FROM ubuntu:22.10@sha256:de3394e00e0e7e0d5f2092ae05a4c652f9918e67efa617565df2a1ed5353bbfb AS ubuntu-22.10

FROM ${base_image}

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        gnome-session gjs dbus-user-session gir1.2-vte-2.91 xvfb

COPY common debian /

# Start Xvfb via systemd on display :99.
# Add the gnomeshell user with no password.
# Unmask required on Fedora 32
RUN systemctl unmask systemd-logind.service console-getty.service getty.target && \
    systemctl enable xvfb@:99.service && \
    systemctl set-default multi-user.target && \
    systemctl mask systemd-oomd && \
    systemctl --global mask xdg-document-portal gnome-keyring && \
    useradd -m -U -G users,adm gnomeshell

# dbus port
EXPOSE 1234

CMD [ "/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
