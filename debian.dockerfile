ARG base_image=ubuntu-22.04

FROM debian:11@sha256:1e5f2d70c9441c971607727f56d0776fb9eecf23cd37b595b26db7a974b2301d AS debian-11
FROM debian:12@sha256:e7072ef5bbeaca98db3056a7d944d5dfb7a44d47770d10d54ee3f5a61144f049 AS debian-12
FROM ubuntu:20.04@sha256:554e40b15453c788ec799badf0f1ad05c3e5c735b53f940feb8f27cf2ec570c5 AS ubuntu-20.04
FROM ubuntu:22.04@sha256:83f0c2a8d6f266d687d55b5cb1cb2201148eb7ac449e4202d9646b9083f1cee0 AS ubuntu-22.04
FROM ubuntu:22.10@sha256:1fa7586c0f10cc7ce7ca379ae48bf06776325b9f8e97963ce40803a8bcc07dca AS ubuntu-22.10
FROM ubuntu:23.04@sha256:09f035f46361d193ded647342903b413d57d05cc06acff8285f9dda9f2d269d5 AS ubuntu-23.04

FROM ${base_image}

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        gnome-session gjs dbus-user-session gir1.2-vte-2.91 xvfb \
        packagekit gir1.2-packagekitglib-1.0

COPY common debian /

# Start Xvfb via systemd on display :99.
# Add the gnomeshell user with no password.
RUN systemctl enable xvfb@:99.service && \
    systemctl set-default multi-user.target && \
    systemctl mask systemd-oomd low-memory-monitor rtkit-daemon && \
    useradd -m -U -G users,adm gnomeshell

# dbus port
EXPOSE 1234
LABEL user-dbus-port=1234

# X11 port
EXPOSE 6099
LABEL x11-port=6099 x11-display-number=99

CMD [ "/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
