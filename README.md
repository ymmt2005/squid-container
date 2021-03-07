![CI](https://github.com/ymmt2005/squid-container/workflows/main/badge.svg)

# Squid container

This directory contains a Dockerfile that runs [Squid](http://www.squid-cache.org/) w/o root privileges.

## Usage

### Run with the default configuration

    $ docker run --rm -d -p 3128:3128 --read-only --tmpfs /var/spool/squid ghcr.io/ymmt2005/squid

### Launch Squid with specific config file

Prepare `squid.conf`, then execute following command.

    $ docker run --rm -d -p 3128:3128 --read-only --tmpfs /var/spool/squid \
        -v /path/to/your/squid.conf:/etc/squid/squid.conf:ro \
        ghcr.io/ymmt2005/squid

Your `squid.conf` must have the following configurations:

    pid_filename   none
    logfile_rotate 0
    access_log     stdio:/dev/stdout
    cache_log      stdio:/dev/stderr

## Docker images

[ghcr.io/ymmt2005/squid](https://github.com/users/ymmt2005/packages/container/package/squid)
