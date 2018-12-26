
# build image
FROM alpine:latest AS prep
ARG TAG=master

# prepare build environmet for cmake
RUN apk update \
 && apk add --no-cache --update bash git gcc linux-headers musl-dev shadow make \
            cmake jpeg-dev raspberrypi-dev v4l-utils-dev imagemagick libgphoto2-dev \
            sdl-dev protobuf-c-dev zeromq-dev \
 && rm -rf /var/cache/apk/*


# get the mjpeg sources and build from source
WORKDIR /usr/src
RUN git clone https://github.com/jacksonliam/mjpg-streamer.git mjpeg-streamer \
 && cd mjpeg-streamer/mjpg-streamer* \
 && git checkout $TAG \
 && mkdir _build && cd _build \
 && cmake -DCMAKE_SHARED_LINKER_FLAGS="-Wl,--no-as-needed" .. \
 && make && make install

# target image
FROM alpine:latest
EXPOSE 8080
# UID and GID of new user
ARG uid=666
ARG gid=666
ARG user=mjpeg-streamer
# GIDs to grant access rights for the new user
ARG gids=666

# set mjpeg library paths
ENV LD_LIBRARY_PATH='/opt/vc/lib/:/usr/local/lib/mjpeg_streamer'

# prepare runtime environment
RUN apk update \
 && apk add --no-cache --update bash musl shadow jpeg raspberrypi v4l-utils-libs \
            libgphoto2 sdl protobuf-c zeromq \
 && rm -rf /var/cache/apk/*
# && echo "export LD_LIBRARY_PATH='/opt/vc/lib/:/usr/local/lib/mjpeg_streamer'" >> /etc/environment

# copy built files
COPY --from=prep /usr/local/lib/mjpg-streamer /usr/local/lib/mjpg-streamer
COPY --from=prep /usr/local/bin/mjpg_streamer /usr/local/bin/mjpg_streamer
COPY --from=prep /usr/local/share/mjpg-streamer/www /usr/local/share/mjpg-streamer/www

# add new user and set groups
RUN groupadd -g ${gid} ${user} \
 && useradd -rNM -s /bin/bash -g ${user} -u ${uid} ${user} \
 && for g in ${gids//,/ }; do \
      echo "New group grp$g"; \
      groupadd -g $g grp$g && usermod -aG grp$g ${user}; \
    done
# swithc user
USER ${user}

ENTRYPOINT [ "/usr/local/bin/mjpg_streamer" ]
CMD [ "-o", "output_http.so -w /usr/local/share/mjpg-streamer/www", "-i", "input_raspicam.so -x 800 -y 600 -fps 10 -vf -vs -rot 0" ]
