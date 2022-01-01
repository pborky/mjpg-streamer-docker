
# Docker Arch (amd64, arm32v6, ...)
ARG TARGET_ARCH
FROM ${TARGET_ARCH}/alpine:3.15 AS base

# Qemu Arch (x86_64, arm, ...)
ARG QEMU_ARCH
ENV QEMU_ARCH=${QEMU_ARCH}
COPY qemu-${QEMU_ARCH}-static /usr/bin/

# build image
FROM base AS build

# prepare build environmet for cmake
RUN set -ex \
  ; apk update \
  ; apk add --no-cache --update bash git gcc linux-headers musl-dev shadow make \
  cmake jpeg-dev raspberrypi-dev v4l-utils-dev imagemagick libgphoto2-dev \
  sdl-dev protobuf-c-dev zeromq-dev \
  ; rm -rf /var/cache/apk/*

ARG TAG=master

# get the mjpeg sources and build from source
WORKDIR /usr/src
RUN set -ex \
  ; git clone https://github.com/jacksonliam/mjpg-streamer.git mjpg-streamer \
  ; cd mjpg-streamer/mjpg-streamer* \
  ; git checkout $TAG \
  ; mkdir _build && cd _build \
  ; cmake -DCMAKE_SHARED_LINKER_FLAGS="-Wl,--no-as-needed" .. \
  ;  make && make install

# target image
FROM base
EXPOSE 8080

# set mjpeg library paths
ENV LD_LIBRARY_PATH='/opt/vc/lib/:/usr/local/lib/mjpeg_streamer'

ARG uid=666
ARG gid=666
ARG user=evil

ARG gids

# prepare runtime environment 
RUN set -ex \
  ; apk update \
  ; apk add --no-cache --update bash musl shadow jpeg raspberrypi v4l-utils-libs \
  libgphoto2 sdl protobuf-c zeromq \
  ; rm -rf /var/cache/apk/* \
  ; groupadd -g ${gid} ${user} \
  ; useradd -rNM -s /bin/bash -g ${user} -u ${uid} ${user} \
  ; for g in ${gids//,/ }; do \
  echo "New group grp $g"; \
  groupadd -g $g grp$g && usermod -aG grp$g ${user}; \
  done \
  ; chmod a+rx /usr/bin/qemu-arm-static 
# && echo "export LD_LIBRARY_PATH='/opt/vc/lib/:/usr/local/lib/mjpeg_streamer'" >> /etc/environment

# copy built files
COPY --from=build /usr/local/lib/mjpg-streamer /usr/local/lib/mjpg-streamer
COPY --from=build /usr/local/bin/mjpg_streamer /usr/local/bin/mjpg_streamer
COPY --from=build /usr/local/share/mjpg-streamer/www /usr/local/share/mjpg-streamer/www

ENTRYPOINT [ "/usr/local/bin/mjpg_streamer" ]
CMD [ "-o", "output_http.so -w /usr/local/share/mjpg-streamer/www", "-i", "input_raspicam.so -x 800 -y 600 -fps 10 -vf -vs -rot 0" ]
