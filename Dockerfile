FROM ubuntu:18.04
RUN groupadd -r haproxy && useradd -r -g haproxy haproxy
RUN set -eux; \
        apt-get update && \
        apt-get install libreadline6-dev -y --no-install-recommends && \
        apt-get install gcc automake autoconf libtool make -y && \
        apt-get install libpcre3-dev -y && \
        apt-get install libz-dev -y && \
        apt-get install curl -y && \
        apt-get install wget -y && \
        apt-get install unzip -y && \
        apt-get install cmake -y && \
        apt-get install libssl-dev -y && \
        apt-get install rsyslog -y
ENV GOSU_VERSION 1.11
RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		wget \
	; \
	if ! command -v gpg > /dev/null; then \
		apt-get install -y --no-install-recommends gnupg dirmngr; \
		savedAptMark="$savedAptMark gnupg dirmngr"; \
	elif gpg --version | grep -q '^gpg (GnuPG) 1\.'; then \
# "This package provides support for HKPS keyservers." (GnuPG 1.x only)
		apt-get install -y --no-install-recommends gnupg-curl; \
	fi; \
	rm -rf /var/lib/apt/lists/*; \
	\
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	command -v gpgconf && gpgconf --kill all || :; \
	rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	chmod +x /usr/local/bin/gosu; \
	gosu --version; \
	gosu nobody true; \
# TODO some sort of download verification here
	\
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark > /dev/null; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false
COPY lua-5.3.5.tar.gz /
COPY luarocks-3.2.1.tar.gz /
COPY mongo-c-driver-1.15.2.tar.gz /
COPY haproxy-2.1.0.tar.gz /
COPY haproxylog.conf /etc/rsyslog.d/haproxylog.conf
ENV LUA_SRC /usr/src/lua
ENV LUAROCK_SRC /usr/src/luarocks
ENV MONGODRIVER_SRC /usr/src/mongo
ENV HAPROXY_SRC /usr/src/haproxy
RUN set -ex; \
    eval "mkdir -p /usr/src/lua" && \
    eval "mkdir -p /usr/src/luarocks" && \
    eval "mkdir -p /usr/src/mongo" && \
    eval "mkdir -p /usr/src/haproxy" && \
    eval "tar -zxvf lua-5.3.5.tar.gz -C ${LUA_SRC}  --strip-components 1" && \
    eval "tar zxpf luarocks-3.2.1.tar.gz  -C ${LUAROCK_SRC}  --strip-components 1" && \
    eval "tar xzf mongo-c-driver-1.15.2.tar.gz  -C ${MONGODRIVER_SRC}  --strip-components 1"  && \
    eval "tar xvzf haproxy-2.1.0.tar.gz  -C ${HAPROXY_SRC}  --strip-components 1" && \
    eval "make -C /usr/src/lua linux test" && \
    eval "make -C /usr/src/lua linux" && \
    eval "make -C /usr/src/lua install" && \
    eval "mkdir -p ${MONGODRIVER_SRC}/cmake-build"
WORKDIR $LUAROCK_SRC
RUN set -ex; \
    eval "./configure" && \
    eval "make" && \
    eval "make install"
WORKDIR ${MONGODRIVER_SRC}/cmake-build
RUN set -ex; \
    eval "cmake -DENABLE_AUTOMATIC_INIT_AND_CLEANUP=OFF .." && \
    eval "make" && \
    eval "make install" && \
    luarocks install lua-mongo
WORKDIR $HAPROXY_SRC
RUN set -ex; \
    eval "make TARGET=linux-glibc USE_PCRE=1 USE_PCRE_JIT=1 USE_OPENSSL=1 USE_ZLIB=1 USE_LINUX_TPROXY=1 USE_REGPARM=1 USE_LUA=1 USE_THREAD=1 USE_TFO=1" && \
    eval "make install"
WORKDIR /

STOPSIGNAL SIGUSR1

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["haproxy", "-f", "/etc/haproxy/conf/haproxy.cfg"]
