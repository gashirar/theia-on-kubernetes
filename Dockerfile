FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive

#Common deps
RUN apt-get update && apt-get -y install curl xz-utils wget gpg

#Install node and yarn
#From: https://github.com/nodejs/docker-node/blob/6b8d86d6ad59e0d1e7a94cec2e909cad137a028f/8/Dockerfile

# gpg keys listed at https://github.com/nodejs/node#release-keys
RUN set -ex \
    && for key in \
    4ED778F539E3634C779C87C6D7062848A1AB005C \
    B9E2F5981AA6E0CD28160D9FF13993A75599653C \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
    ; do \
    gpg --batch --keyserver ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver pgp.mit.edu --recv-keys "$key" || \
    gpg --batch --keyserver keyserver.pgp.com --recv-keys "$key" || \
    gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" ; \
    done

ARG NODE_VERSION=10.15.3
ENV NODE_VERSION $NODE_VERSION

RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
    amd64) ARCH='x64';; \
    ppc64el) ARCH='ppc64le';; \
    s390x) ARCH='s390x';; \
    arm64) ARCH='arm64';; \
    armhf) ARCH='armv7l';; \
    i386) ARCH='x86';; \
    *) echo "unsupported architecture"; exit 1 ;; \
    esac \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
    && curl -SLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
    && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs

ENV YARN_VERSION 1.13.0

RUN set -ex \
    && for key in \
    6A010C5166006599AA17F08146C2130DFD2497F5 \
    ; do \
    gpg --batch --keyserver ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver pgp.mit.edu --recv-keys "$key" || \
    gpg --batch --keyserver keyserver.pgp.com --recv-keys "$key" || \
    gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" ; \
    done \
    && curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
    && curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
    && gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
    && mkdir -p /opt/yarn \
    && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/yarn --strip-components=1 \
    && ln -s /opt/yarn/bin/yarn /usr/local/bin/yarn \
    && ln -s /opt/yarn/bin/yarn /usr/local/bin/yarnpkg \
    && rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz

#Developer tools

## Git and sudo (sudo needed for user override)
RUN apt-get -y install git sudo

#LSPs

##GO
ENV GO_VERSION 1.11.4
ENV GOPATH=/usr/local/go-packages
ENV GO_ROOT=/usr/local/go
ENV PATH $PATH:/usr/local/go/bin
ENV PATH $PATH:${GOPATH}/bin

RUN curl -sS https://storage.googleapis.com/golang/go$GO_VERSION.linux-amd64.tar.gz | tar -C /usr/local -xzf - && \
    go get -u -v github.com/nsf/gocode && \
    go get -u -v github.com/uudashr/gopkgs/cmd/gopkgs && \
    go get -u -v github.com/ramya-rao-a/go-outline && \
    go get -u -v github.com/acroca/go-symbols && \
    go get -u -v golang.org/x/tools/cmd/guru && \
    go get -u -v golang.org/x/tools/cmd/gorename && \
    go get -u -v github.com/fatih/gomodifytags && \
    go get -u -v github.com/haya14busa/goplay/cmd/goplay && \
    go get -u -v github.com/josharian/impl && \
    go get -u -v github.com/tylerb/gotype-live && \
    go get -u -v github.com/rogpeppe/godef && \
    go get -u -v golang.org/x/tools/cmd/godoc && \
    go get -u -v github.com/zmb3/gogetdoc && \
    go get -u -v golang.org/x/tools/cmd/goimports && \
    go get -u -v sourcegraph.com/sqs/goreturns && \
    go get -u -v github.com/golang/lint/golint && \
    go get -u -v github.com/cweill/gotests/... && \
    go get -u -v github.com/alecthomas/gometalinter && \
    go get -u -v honnef.co/go/tools/... && \
    go get -u -v github.com/sourcegraph/go-langserver && \
    go get -u -v github.com/derekparker/delve/cmd/dlv && \
    go get -u -v github.com/davidrjenni/reftools/cmd/fillstruct

#Java
RUN apt-get update && apt-get -y install openjdk-8-jdk maven gradle

## User account
RUN adduser --disabled-password --gecos '' theia && \
    adduser theia sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers;

RUN chmod g+rw /home && \
    mkdir -p /home/project && \
    mkdir -p /usr/local/cargo && \
    mkdir -p /usr/local/go && \
    mkdir -p /usr/local/go-packages && \
    chown -R theia:theia /usr/local/cargo && \
    chown -R theia:theia /usr/local/go && \
    chown -R theia:theia /usr/local/go-packages && \
    chown -R theia:theia /home/theia && \
    chown -R theia:theia /home/project;

#Theia
##Needed for node-gyp, nsfw build
RUN apt-get update && apt-get install -y python build-essential

USER theia
WORKDIR /home/theia
ADD ./package.json ./package.json
ADD ./yarn.lock ./yarn.lock
RUN yarn --cache-folder ./ycache && rm -rf ./ycache && \
    NODE_OPTIONS="--max_old_space_size=4096" yarn theia build
EXPOSE 3000
ENV SHELL /bin/bash

ENV GOPATH=/home/theia
ENV PATH=$PATH:$GOPATH/bin

USER root

RUN apt-get update && apt-get -y install bash-completion

## kubectl
RUN KUBECTL_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)  && \
    curl -LO https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl  && \
    chmod +x ./kubectl  && \
    sudo -S mv ./kubectl /usr/local/bin/kubectl

## helm
RUN HELM_VERSION=v2.14.3 && \
    mkdir /tmp/helm && \
    curl -L https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz -o /tmp/helm/helm.tar.gz && \
    tar xvf /tmp/helm/helm.tar.gz -C /tmp/helm/ && \ 
    chmod +x /tmp/helm/linux-amd64/helm && \
    sudo -S mv /tmp/helm/linux-amd64/helm /usr/local/bin/helm && \
    rm -r /tmp/helm

## kustomize
RUN KUSTOMIZE_VERSION=3.1.0 && \
    curl -L https://github.com/kubernetes-sigs/kustomize/releases/download/v${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64 -o ./kustomize && \
    chmod +x ./kustomize && \
    sudo -S mv ./kustomize /usr/local/bin/kustomize

## kubectx & kubens & fzf
RUN git clone https://github.com/ahmetb/kubectx /opt/kubectx && \
    ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx && \
    ln -s /opt/kubectx/kubens /usr/local/bin/kubens && \
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && \
    ~/.fzf/install

ADD ./server.js ./src-gen/backend/server.js
RUN echo "source <(kubectl completion bash)" >> /home/theia/.bashrc && \
    echo 'export PS1="\[\e]0;\u@\h: \w\a\]\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> /home/theia/.bashrc && \
    echo '[ -f ~/.fzf.bash ] && source ~/.fzf.bash' >> /home/theia/.bashrc
USER theia

ENV DEFAULT_USER="user"
ENV USER=${USER:-$DEFAULT_USER}

ENV DEFAULT_PASSWORD="P@ssw0rd"
ENV PASSWORD=${PASSWORD:-$DEFAULT_PASSWORD}

ENTRYPOINT [ "yarn", "theia", "start", "/home/theia", "--hostname=0.0.0.0" ]
