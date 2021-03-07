# squid container

FROM ubuntu:20.04 as build

ARG SQUID_VERSION=4.14

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        openssl \
        libreadline8 \
        ca-certificates \
        curl \
        build-essential \
        libreadline-dev \
        libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
# refer https://salsa.debian.org/squid-team/squid/-/blob/master/debian/rules
RUN curl -sfLO http://www.squid-cache.org/Versions/v4/squid-${SQUID_VERSION}.tar.xz \
    && tar --strip-components=1 -xf /work/squid-${SQUID_VERSION}.tar.xz \
    && ./configure --without-gnutls --with-openssl --without-systemd \
                   --sysconfdir=/etc/squid --with-swapdir=/var/spool/squid \
                   --with-logdir=/var/log/squid --with-pidfile=/run/squid.pid \
                   --with-filedescriptors=65536 --with-large-files \
    && make -j "$(nproc)" \
    && make install

# stage2: production image
FROM ubuntu:20.04

COPY --from=build /usr/local/squid /usr/local/squid
COPY --from=build /etc/squid /etc/squid

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        locales \
        tzdata \
        openssl \
        libreadline8 \
        ca-certificates \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    && echo "Etc/UTC" > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

# Redirect logs to stdout/stderr for the container
# Note that the default squid.conf does not enable disk cache.
# /var/spool/squid is only used for coredumps.
RUN mkdir -p /var/log/squid \
    && chown 10000:10000 /var/log/squid \
    && echo 'pid_filename none' >>/etc/squid/squid.conf \
    && echo 'logfile_rotate 0' >>/etc/squid/squid.conf \
    && echo 'access_log stdio:/dev/stdout' >>/etc/squid/squid.conf \
    && echo 'cache_log stdio:/dev/stderr' >>/etc/squid/squid.conf \
    && mkdir -p /var/spool/squid \
    && chown -R 10000:10000 /var/spool/squid

ENV PATH=/usr/local/squid/sbin:/usr/local/squid/bin:$PATH
USER 10000:10000
EXPOSE 3128

ENTRYPOINT ["/usr/local/squid/sbin/squid", "-N"]
