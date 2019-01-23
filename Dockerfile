FROM ubuntu:16.04

#Common deps
RUN apt-get update && apt-get -y install curl xz-utils wget bash-completion

#Install node and yarn
#From: https://github.com/nodejs/docker-node/blob/6b8d86d6ad59e0d1e7a94cec2e909cad137a028f/8/Dockerfile

# gpg keys listed at https://github.com/nodejs/node#release-keys
RUN set -ex \
  && for key in \
  94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
  FD3A5288F042B6850C66B31F09FE44734EB7990E \
  71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
  DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
  C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
  B9AE9905FFD7803F25714661B63B535A4C206CA9 \
  56730D5401028683275BD23C23EFEFE93C4CFFFE \
  77984A986EBC2AA786BC0F66B01FBB92821C587A \
  ; do \
  gpg --keyserver pool.sks-keyservers.net --recv-keys "$key" || \
  gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
  gpg --keyserver keyserver.pgp.com --recv-keys "$key" || \
  gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" ; \
  done
  

ENV NODE_VERSION 8.12.0

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

ENV YARN_VERSION 1.9.4

RUN set -ex \
  && for key in \
  6A010C5166006599AA17F08146C2130DFD2497F5 \
  ; do \
  gpg --keyserver pool.sks-keyservers.net --recv-keys "$key" || \
  gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
  gpg --keyserver keyserver.pgp.com --recv-keys "$key" || \
  gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" ; \
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

#Required to use go get with git source
RUN apt-get update && apt-get install -y git

ENV GO_VERSION 1.9.4
ENV GOPATH=/usr/local/go-packages
ENV GO_ROOT=/usr/local/go
ENV PATH $PATH:/usr/local/go/bin
ENV PATH $PATH:${GOPATH}/bin

RUN curl -sS https://storage.googleapis.com/golang/go$GO_VERSION.linux-amd64.tar.gz | tar -C /usr/local -xzf -
RUN go get -u -v github.com/ramya-rao-a/go-outline && \
    go get -u -v github.com/acroca/go-symbols && \
    go get -u -v github.com/nsf/gocode && \
    go get -u -v github.com/rogpeppe/godef && \
    go get -u -v golang.org/x/tools/cmd/godoc && \
    go get -u -v github.com/zmb3/gogetdoc && \
    go get -u -v golang.org/x/lint/golint && \
    go get -u -v github.com/fatih/gomodifytags && \
    go get -u -v github.com/uudashr/gopkgs/cmd/gopkgs && \
    go get -u -v golang.org/x/tools/cmd/gorename && \
    go get -u -v sourcegraph.com/sqs/goreturns && \
    go get -u -v github.com/cweill/gotests/... && \
    go get -u -v golang.org/x/tools/cmd/guru && \
    go get -u -v github.com/josharian/impl && \
    go get -u -v github.com/haya14busa/goplay/cmd/goplay && \
    go get -u -v github.com/davidrjenni/reftools/cmd/fillstruct

## kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

# helm
RUN mkdir /tmp/helm && \
    curl -L https://storage.googleapis.com/kubernetes-helm/helm-v2.12.1-linux-amd64.tar.gz -o /tmp/helm/helm.tar.gz && \
    tar xvf /tmp/helm/helm.tar.gz -C /tmp/helm/ && \
    chmod +x /tmp/helm/linux-amd64/helm && \
    mv /tmp/helm/linux-amd64/helm /usr/local/bin/helm

# kustomize
RUN curl -L https://github.com/kubernetes-sigs/kustomize/releases/download/v1.0.11/kustomize_1.0.11_linux_amd64 -o ./kustomize && \
    chmod +x ./kustomize && \
    mv ./kustomize /usr/local/bin/kustomize

## User account
RUN adduser --disabled-password --gecos '' theia && \
    adduser theia sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers;

RUN echo "source <(kubectl completion bash)"\n >> ~/.bashrc

RUN chmod g+rw /home && \
    mkdir -p /home/project && \
    chown -R theia:theia /home/theia && \
    chown -R theia:theia /home/project;

#Theia
##Needed for node-gyp, nsfw build
RUN apt-get update && apt-get install -y python build-essential

USER theia
ARG version=latest
WORKDIR /home/theia
ADD ./package.json ./package.json
ARG GITHUB_TOKEN
RUN yarn --cache-folder ./ycache && rm -rf ./ycache
# using "NODE_OPTIONS=..." to avoid out-of-memory problem in CI
RUN NODE_OPTIONS="--max_old_space_size=4096" yarn theia build
EXPOSE 3000
ENV SHELL /bin/bash

RUN echo "source <(kubectl completion bash)\n" >> ~/.bashrc

CMD [ "yarn", "theia", "start", "/home/project", "--hostname=0.0.0.0" ]

