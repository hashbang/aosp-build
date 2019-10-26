ARG GOLANG_IMAGE_REF=sha256:84349ee862d8bafff35e0d2bfd539da565b536b4dfce654773fc21a1db2da6d7
ARG UBUNTU_IMAGE_REF=sha256:7d657275047118bb77b052c4c0ae43e8a289ca2879ebfa78a703c93aa8fd686c

FROM golang@${GOLANG_IMAGE_REF} as golang

ARG FIXUID_GIT_REF="0ec93d22e52bde5b7326e84cb62fd26a3d20cead"
ARG OZZOCONFIG_GIT_REF="0ff174cf5aa6480026e0b40c14fd9cfb61c4abf6"
ARG JSONPREPROCESS_GIT_REF="a4e954386171be645f1eb7c41865d2624b69259d"
ARG TOML_GIT_REF="3012a1dbe2e4bd1391d42b32f0577cb7bbc7f005"
ARG YAMLV2_GIT_REF="51d6538a90f86fe93ac480b35f37b2be17fef232"
ARG GLIDE_GIT_REF="b94b39d657d8abcccba6545e148f1201aee6ffec"
ARG KUBERNETES_GIT_REF="e298fc723f2597697b770f88ce47fe93507f7463"
ARG HELM_GIT_REF="e70f012bb6b7b4aa19aa7190d68e182cb1f5b9cb"
ARG TERRAFORM_GIT_REF="4ebf9082cde695a4bbc908cbf373a2c8139fe534"
ARG TERRAFORM_HELM_GIT_REF="a8e657341b68c09f901736974aee3aeccdd38be9"
ARG TERRAFORM_KUBERNETES_GIT_REF="56bb8e012f5f4bdd2fb906e1e6a567e3e57b46a4"

RUN apk add bash git make

RUN printf "\
github.com/boxboat/fixuid.git github.com/boxboat/fixuid ${FIXUID_GIT_REF} \n\
github.com/go-ozzo/ozzo-config github.com/go-ozzo/ozzo-config ${OZZOCONFIG_GIT_REF} \n\
github.com/hnakamur/jsonpreprocess github.com/hnakamur/jsonpreprocess ${JSONPREPROCESS_GIT_REF} \n\
github.com/BurntSushi/toml github.com/BurntSushi/toml ${TOML_GIT_REF} \n\
github.com/go-yaml/yaml gopkg.in/yaml.v2 ${YAMLV2_GIT_REF} \n\
github.com/Masterminds/glide github.com/Masterminds/glide ${GLIDE_GIT_REF} \n\
github.com/kubernetes/kubernetes k8s.io/kubernetes ${KUBERNETES_GIT_REF} \n\
github.com/helm/helm k8s.io/helm ${HELM_GIT_REF} \n\
github.com/hashicorp/terraform github.com/hashicorp/terraform ${TERRAFORM_GIT_REF} \n\
github.com/terraform-providers/terraform-provider-helm github.com/terraform-providers/terraform-provider-helm ${TERRAFORM_HELM_GIT_REF} \n\
github.com/terraform-providers/terraform-provider-kubernetes github.com/terraform-providers/terraform-provider-kubernetes ${TERRAFORM_KUBERNETES_GIT_REF}\n" \
> /go/src/repos

RUN echo ' \
    set -o nounset -o pipefail -o errexit; \
    cat /go/src/repos | while read -r line; do \
        repo=$(echo $line | awk "{ print \$1 }"); \
        folder=$(echo $line | awk "{ print \$2 }"); \
        ref=$(echo $line | awk "{ print \$3 }"); \
        git clone "https://${repo}" "/go/src/${folder}"; \
        git -C "/go/src/${folder}" checkout ${ref};  \
    done' \
| bash

RUN go build -o /usr/local/bin/fixuid github.com/boxboat/fixuid
RUN go build -o /usr/local/bin/glide github.com/Masterminds/glide
RUN go build -o /usr/local/bin/kubectl k8s.io/kubernetes/cmd/kubectl
RUN cd /go/src/k8s.io/helm \
    && make bootstrap build \
    && cp bin/helm /usr/local/bin/ \
    && cp bin/tiller /usr/local/bin/
RUN go build -o /usr/local/bin/terraform github.com/hashicorp/terraform
RUN go build -o /usr/local/bin/terraform-provider-kubernetes \
    github.com/terraform-providers/terraform-provider-kubernetes
RUN go build -o /usr/local/bin/terraform-provider-helm \
    github.com/terraform-providers/terraform-provider-helm


FROM ubuntu:cosmic@${UBUNTU_IMAGE_REF}

COPY --from=golang /usr/local/bin/ /usr/local/bin/

ENV HOME=/home/build
ENV PATH=/home/build/scripts:/opt/aosp-build/scripts:/home/build/out/host/linux-x86/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TZ=UTC \
    TERM=xterm-256color

ENTRYPOINT ["/usr/local/bin/fixuid", "-q"]
WORKDIR /home/build

CMD [ "/bin/bash", "/usr/local/bin/build" ]

ADD config/container/sources.list /etc/apt/sources.list
ADD config/container/packages.list /etc/apt/packages.list
RUN apt update -y \
    && apt install -y $(cat /etc/apt/packages.list) \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD config /opt/aosp-build/config
ADD scripts /opt/aosp-build/scripts

RUN chown root:root /usr/local/bin/fixuid \
    && chmod 4755 /usr/local/bin/fixuid \
    && mkdir -p /etc/fixuid \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && printf "user: build\ngroup: build\npaths:\n  - /\n  - /home/build/build\n" > /etc/fixuid/config.yml \
    && useradd -G plugdev,sudo -ms /bin/bash build \
    && chown -R build:build /home/build

USER build
