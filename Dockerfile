
# build image
FROM alpine:latest AS prep
ARG TAG=master

# prepare build environmet for cmake
RUN apk update \
 && apk upgrade \
 && apk add --no-cache --update bash git gcc linux-headers musl-dev shadow make \
            cmake jpeg-dev raspberrypi-dev v4l-utils-dev imagemagick libgphoto2-dev \
            sdl-dev protobuf-c-dev \
 && rm -rf /var/cache/apk/*


# get the mjpeg sources and build from source
WORKDIR /usr/src
RUN git clone https://github.com/jacksonliam/mjpg-streamer.git mjpeg-streamer \
 && cd mjpeg-streamer/mjpg-streamer* \
 && git checkout $TAG \
 && mkdir _build && cd _build \
 && cmake -DCMAKE_SHARED_LINKER_FLAGS="-Wl,--no-as-needed" .. \
 && make \
 && make install

# target image
FROM alpine:latest 
EXPOSE 8080
ARG uid=666
ARG gid=666
ARG name=mjpeg-streamer

# prepare runtime environment
RUN apk update \
 && apk upgrade \
 && apk add --no-cache --update bash musl shadow jpeg raspberrypi v4l-utils-libs libgphoto2 \
            sdl protobuf-c  \
 && rm -rf /var/cache/apk/*

# copy build files
COPY --from=prep /usr/local/lib/mjpg-streamer /usr/local/lib/mjpg-streamer
COPY --from=prep /usr/local/bin/mjpg_streamer /usr/local/bin/mjpg_streamer
COPY --from=prep /usr/local/share/mjpg-streamer/www /usr/local/share/mjpg-streamer/www
COPY mjpeg_streamer.sh /usr/local/bin/

# switch user
RUN groupadd -g ${gid} ${name} \
 && useradd -rNM -s /bin/bash -G dialout -g ${name} -u ${uid} ${name}
USER ${name}

CMD [ "/usr/local/bin/mjpeg_streamer.sh"]
