
FROM alpine:latest AS prep
ARG TAG=master

RUN apk update \
 && apk upgrade \
 && apk add --no-cache --update bash git gcc linux-headers musl-dev shadow make \
            cmake jpeg-dev raspberrypi-dev v4l-utils-dev imagemagick libgphoto2-dev \
            sdl-dev protobuf-c-dev \
 && rm -rf /var/cache/apk/*

WORKDIR /usr/src

RUN git clone https://github.com/jacksonliam/mjpg-streamer.git mjpeg-streamer \
 && cd mjpeg-streamer/mjpg-streamer* \
 && git checkout $TAG \
 && mkdir _build && cd _build \
 && cmake -DCMAKE_SHARED_LINKER_FLAGS="-Wl,--no-as-needed" .. \
 && make \
 && make install

FROM alpine:latest 

EXPOSE 8080

RUN apk update \
 && apk upgrade \
 && apk add --no-cache --update musl shadow jpeg raspberrypi v4l-utils-libs libgphoto2 \
            sdl protobuf-c  \
 && rm -rf /var/cache/apk/*

COPY --from=prep /usr/local/lib/mjpg-streamer /usr/local/lib/mjpg-streamer
COPY --from=prep /usr/local/bin/mjpg_streamer /usr/local/bin/mjpg_streamer
COPY --from=prep /usr/local/share/mjpg-streamer/www /usr/local/share/mjpg-streamer/www
COPY mjpeg_streamer.sh /usr/local/bin/


CMD [ "/usr/local/bin/mjpeg_streamer.sh"]