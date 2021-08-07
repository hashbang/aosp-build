# This file was generated using a Jinja2 template.
# Please make your changes in `Dockerfile.j2` and then `make` the individual Dockerfile's.

ARG DEBIAN_IMAGE_REF=@sha256:8414aa82208bc4c2761dc149df67e25c6b8a9380e5d8c4e7b5c84ca2d04bb244



FROM debian:buster${DEBIAN_IMAGE_REF}

ARG DEBIAN_FRONTEND=noninteractive


ENV HOME=/home/build
ENV PATH=/home/build/scripts:/opt/aosp-build/scripts:/home/build/out/host/linux-x86/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ENV LANG=C.UTF-8 \
    TZ=UTC \
    TERM=xterm-256color

ADD config/container/sources.list /etc/apt/sources.list
ADD config/container/packages-pinned.list /etc/apt/packages.list

RUN apt-get update \
    && apt-get install -y $(grep -v '^#' /etc/apt/packages.list) \
    && sed --in-place '/en_US.UTF-8/s/^#\s*//;' /etc/locale.gen \
    && dpkg-reconfigure locales \
    && update-locale LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD config /opt/aosp-build/config
ADD scripts /opt/aosp-build/scripts

RUN useradd -G plugdev,sudo -ms /bin/bash build \
    && chown -R build:build /home/build \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers


WORKDIR /home/build

CMD [ "/bin/bash", "/usr/local/bin/build" ]

USER build

# Other scripts might also need to use git. So do it here.
RUN printf "[color]\nui=auto\n[user]\nemail=aosp@example.org\nname=AOSP User" > ~/.gitconfig
