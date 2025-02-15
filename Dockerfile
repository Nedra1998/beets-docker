FROM alpine:3.21 AS main

LABEL name="docker-beets" \
      maintainer="Arden Rasmussen" \
      description="Beets is the media library management system for obsessive music geeks." \
      url="https://beets.io" \
      org.label-schema.vcs-url="http://vega.lyra:9070/Arden/beets-docker" \
      org.opencontainers.image.source="http://vega.lyra:9070/Arden/beets-docker"

COPY rootfs /

WORKDIR /src

ENV HOME=/config \
    BEETSDIR=/config/.config/beets \
    FPCALC=/usr/bin/fpcalc \
    UMASK_SET=022 \
    TZ=America/Los_Angeles

RUN apk update && \
    apk upgrade && \
    apk add --no-cache --virtual=base --upgrade \
        bash \
	    bash-completion \
        vim \
        curl \
        wget \
        ca-certificates \
        coreutils \
        procps \
        tar \
        xz \
        gzip \
        tzdata && \
    apk add --no-cache --virtual=build-dependencies --upgrade \
        build-base \
        git \
        zip \
        make \
        cmake \
        g++ \
        gcc \
        musl-dev \
        cargo \
        libffi-dev \
        zlib-dev \ 
        python3-dev \
        openssl-dev \
        jpeg-dev \
        libpng-dev \
        mpg123-dev \
        ffmpeg-dev \
        fftw-dev && \
    apk add --upgrade --no-cache \
        python3 \
        py3-pip \
        inotify-tools \
        chromaprint \
        expat \
        ffmpeg \
        ffmpeg-libs \
        fftw \
        flac \
        gdbm \
        gst-plugins-good \
        gstreamer \
        py3-gobject3 \
        lame \
        libffi \
        libev \
        mpg123 \
        imagemagick \
        jpeg \
        libpng \
        openjpeg \
        sqlite-libs \
        keyfinder-cli

RUN apk add --no-cache --virtual=mp3gain --upgrade --repository="https://dl-cdn.alpinelinux.org/alpine/edge/testing/" \
        mp3gain \
        mp3val && \
    pip3 install --no-cache-dir --upgrade --break-system-packages \
        https://github.com/beetbox/beets/tarball/master \
        #https://github.com/Holzhaus/beets-extrafiles/tarball/master \
        https://github.com/jee-r/beets-extrafiles/tarball/main \
        beetcamp \
        python3-discogs-client \
        beets-lidarr-fields \
        beets-noimport \
        pyacoustid \
        wheel \
        requests \
        beautifulsoup4 \
        pillow \
        unidecode \
        pylast && \
    # install Beet Bash completion
    beet completion > /usr/share/bash-completion/completions/beet && \
    chmod +x /usr/local/bin/entrypoint.sh && \
    apk del --purge build-dependencies && \
    rm -rf /tmp/* /pkgs ~/.cache

CMD ["/usr/local/bin/entrypoint.sh"]
