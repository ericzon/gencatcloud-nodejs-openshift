FROM debian:jessie

MAINTAINER suport.cloud@gencat.cat

# Aquesta imatge es basa en la imatge oficial de node, però no tenen imatge del a versió 4.2.6 -> https://hub.docker.com/_/node/

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r node && useradd -r -g node node

#Install curl
RUN apt-get update && apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		wget \
		unzip \
	&& rm -rf /var/lib/apt/lists/*
	
RUN apt-get update && apt-get install -y xz-utils
RUN apt-get update && apt-get install -y policycoreutils

# gpg keys listed at https://github.com/nodejs/node
RUN set -ex \
  && for key in \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
  ; do \
    gpg --keyserver pool.sks-keyservers.net --recv-keys "$key"; \
  done

ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 4.2.6

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt
  
#install pm2
RUN npm install pm2 -g && pm2 update

RUN mkdir -p /data && chown -R node:node /data \
    && test "$(id node)" = "uid=999(node) gid=999(node) groups=999(node)"

COPY docker-setup.sh /
RUN chmod 0755 /docker-setup.sh
RUN /docker-setup.sh
	
# Define working directory.
WORKDIR /data	
VOLUME /data

#Fitxer d'entrada
COPY run.sh /entrypoint.sh
RUN chmod 0755 /entrypoint.sh

#Copiem el fitxer wait-for-it
COPY wait-for-it.sh /
RUN chmod 0755 /wait-for-it.sh

USER 999

CMD [ "/entrypoint.sh" ]