FROM ubuntu:cosmic

MAINTAINER Hashbang Team <team@hashbang.sh>

ENV HOME=/home/build
ENV PATH=/home/build/scripts:/home/build/out/host/linux-x86/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ARG UID=1000
ARG GID=1000

ARG DEBIAN_FRONTEND=noninteractive

RUN \
    groupadd -g $GID -o build && \
    useradd -G plugdev,sudo -g $GID -u $UID -ms /bin/bash build && \
    apt-get update && \
    apt-get install -y \
        vim \
        repo \
        aapt \
        sudo \
        openjdk-8-jdk \
        android-tools-adb \
        bc \
        bsdmainutils \
        cgpt \
        bison \
        build-essential \
        curl \
        diffoscope \
        flex \
        git \
        g++-multilib\
        gcc-multilib\
        gnupg \
        gperf\
        golang \
        imagemagick \
        libncurses5 \
        lib32ncurses5-dev \
        lib32readline-dev \
        lib32z1-dev \
        liblz4-tool \
        libncurses5-dev \
        libsdl1.2-dev \
        libssl-dev \
        libwxgtk3.0-dev \
        libxml2 \
        libxml2-utils \
        lzop \
        libfaketime \
        ninja-build \
        pngcrush \
        python3 \
        python3-git \
        python3-yaml \
        rsync \
        schedtool \
        squashfs-tools \
        xsltproc \
        yasm \
        zip \
        zlib1g-dev \
        python-six \
        wget \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && echo "[color]\nui = auto\n[user]\nemail = aosp@example.org\nname = AOSP User" >> /etc/gitconfig \
    && git clone https://github.com/boxboat/fixuid.git fixuid/src/fixuid \
    && git -C "fixuid/src/fixuid" reset --hard \
    	0ec93d22e52bde5b7326e84cb62fd26a3d20cead \
    && git clone https://github.com/go-ozzo/ozzo-config \
    	"fixuid/src/github.com/go-ozzo/ozzo-config" \
    && git -C "fixuid/src/github.com/go-ozzo/ozzo-config" reset --hard \
    	0ff174cf5aa6480026e0b40c14fd9cfb61c4abf6 \
    && git clone https://github.com/hnakamur/jsonpreprocess \
    	"fixuid/src/github.com/hnakamur/jsonpreprocess" \
    && git -C "fixuid/src/github.com/hnakamur/jsonpreprocess" reset --hard \
    	a4e954386171be645f1eb7c41865d2624b69259d \
    && git clone https://github.com/BurntSushi/toml \
    	"fixuid/src/github.com/BurntSushi/toml" \
    && git -C "fixuid/src/github.com/BurntSushi/toml" reset --hard \
    	3012a1dbe2e4bd1391d42b32f0577cb7bbc7f005 \
    && git clone https://github.com/go-yaml/yaml \
    	"fixuid/src/gopkg.in/yaml.v2" \
    && git -C "fixuid/src/gopkg.in/yaml.v2" reset --hard \
    	7b8349ac747c6a24702b762d2c4fd9266cf4f1d6 \
    && env GOPATH="$PWD/fixuid" GOOS=linux GOARCH=amd64 CGO_ENABLED=0 \
    	go build -o "/usr/local/bin/fixuid" fixuid \
    && rm -rf "fixuid" \
    && rm -rf "/home/build/.cache" \
    && chown root:root /usr/local/bin/fixuid \
    && chmod 4755 /usr/local/bin/fixuid \
    && mkdir -p /etc/fixuid \
    && printf "user: build\ngroup: build\n" > /etc/fixuid/config.yml

ENTRYPOINT ["/usr/local/bin/fixuid", "-q"]

USER build
WORKDIR /home/build
ADD scripts/ /usr/local/bin/
ADD config.yml /home/build/config.yml
ADD manifests /home/build/manifests
ADD overlay /home/build/overlay

CMD [ "/bin/bash", "/usr/local/bin/build.sh" ]
