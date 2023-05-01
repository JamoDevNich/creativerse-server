FROM steamcmd/steamcmd:ubuntu
LABEL maintainer="jamodevnich <github@nich.dev>" version="1.0.0"

# Define configuration variables
ENV CREATIVERSE_DIR_DATA="/root/Steam/steamapps/common/Creativerse Dedicated Server" \
    CREATIVERSE_DIR_CONFIGURATION="/root/Steam/steamapps/common/Creativerse Dedicated Server/PlayfulCorp/CreativerseServer" \
    CREATIVERSE_DIR_BACKUPS=/srv/creativerse-server/backups \
    CREATIVERSE_DIR_TEMPLATES=/srv/creativerse-server/templates \
    CREATIVERSE_DIR_WORLDS=/srv/creativerse-server/worlds \
    CREATIVERSE_WORLD_KEY=AUTO \
    CREATIVERSE_WORLD_BACKUPS_TO_KEEP=2 \
    CREATIVERSE_WORLD_BACKUPS_MINIMUM_INTERVAL_MINS=5 \
    CREATIVERSE_SERVER_ALWAYSFULLYVERIFYTEMPLATEFILE=false \
    CREATIVERSE_SERVER_MAXMIGRATIONDOWNLOADTHREADS=4

# Install libicu (Internationalisation), jq (Modifying json config files), moreutils (for sponge, allowing changes made by jq to be persisted)
RUN DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    echo "Searching for libicu package..." && \
    LIBICU_PACKAGE=$(apt-cache search libicu[0-9]{2} | cut -d " " -f 1) && \
    echo "...using $LIBICU_PACKAGE for libicu" && \
    apt-get install $LIBICU_PACKAGE jq moreutils -y && \
    rm -rf /var/lib/apt/lists/*

# Copy over any working files from repository, and set up folder structure
WORKDIR /srv
RUN mkdir --verbose --parents "$CREATIVERSE_DIR_DATA" && \
    mkdir --verbose --parents "$CREATIVERSE_DIR_CONFIGURATION" && \
    mkdir --verbose --parents $CREATIVERSE_DIR_BACKUPS && \
    mkdir --verbose --parents $CREATIVERSE_DIR_TEMPLATES && \
    mkdir --verbose --parents $CREATIVERSE_DIR_WORLDS && \
    mkdir --verbose --parents /root/.steam/sdk64 && \
    rm --verbose -r /tmp/dumps /root/Steam/logs/* /root/Steam/appcache/* && \
    chmod --verbose --recursive a=rwxt /srv /root/Steam /root/.steam && \
    chmod --verbose a=xt /root /root/.local /root/.local/share
COPY . .

# Gameport, Queryport, Webserver port
EXPOSE 26900/udp 26901/udp 26902/tcp

# Temporary healthcheck
#HEALTHCHECK --start-period=10m --interval=20s --timeout=2s --retries=3 \
#    CMD nc -zv 127.0.0.1:26902

ENTRYPOINT ["/bin/bash", "init.sh"]
