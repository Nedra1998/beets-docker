FROM alpine:3

LABEL name="docker-beets" \
  maintainer="Arden Rasmussen" \
  description="Beets is the media library management system for obsessive music geeks." \
  url="https://beets.io" \
  org.label-schema.vcs-url="http://github.com/Nedra1998/beets-docker" \
  org.opencontainers.image.source="http://github.com/Nedra1998/beets-docker"

WORKDIR /src

RUN apk update && apk upgrade && \
    apk add --no-cache --virtual=build-dependencies --upgrade \
      build-base cairo-dev cargo cmake ffmpeg-dev fftw-dev git \
      gobject-introspection-dev jpeg-dev libpng-dev mpg123-dev openjpeg-dev \
      python3-dev && \
    apk add --no-cache \
      bash chromaprint expat ffmpeg fftw flac gdbm gobject-introspection \
      gst-plugins-good gstreamer imagemagick jpeg lame libffi libpng mpg123 \
      nano openjpeg python3 py3-pip sqlite-libs mp3gain inotify-tools && \
    apk add --no-cache --virtual=mp3gain --upgrade --repository="https://dl-cdn.alpinelinux.org/alpine/edge/testing/" \
      mp3val && \
    pip3 install --no-cache-dir --upgrade --break-system-packages \
      'beets[chroma,embedart,fetchart,lastgenre,lyrics,replaygain] @ git+https://github.com/beetbox/beets.git' \
      beetcamp beets-copyartifacts3 && \
    apk del --purge build-dependencies && \
    rm -rf /tmp/* /pkgs $HOME/.cache $HOME/.cargo

COPY rootfs /
ENV BEETSDIR=/config
RUN chmod +x /usr/local/bin/entrypoint.sh

CMD ["/usr/local/bin/entrypoint.sh"]
