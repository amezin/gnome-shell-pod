ARG base_image=ubuntu-22.04

FROM debian:11@sha256:bfe6615d017d1eebe19f349669de58cda36c668ef916e618be78071513c690e5 AS debian-11
FROM ubuntu:20.04@sha256:b25ef49a40b7797937d0d23eca3b0a41701af6757afca23d504d50826f0b37ce AS ubuntu-20.04
FROM ubuntu:22.04@sha256:dda6886d8d153a2d86f046c9335123c6151d83fd63e446b752ed8d9da261205d AS ubuntu-22.04
FROM ubuntu:22.10@sha256:4f9ec2c0aa321966bfe625bc485aa1d6e96549679cfdf98bb404dfcb8e141a7f AS ubuntu-22.10

FROM ${base_image}

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        gnome-session gjs dbus-user-session gir1.2-vte-2.91 xvfb xdotool xautomation

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
