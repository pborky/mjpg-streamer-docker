
FROM alpine:latest AS prep
ARG TAG=master

RUN apk update \
 && apk upgrade \
 && apk add --no-cache --update bash git gcc linux-headers musl-dev shadow make \
            cmake jpeg-dev raspberrypi-dev v4l-utils-dev imagemagick\
 && rm -rf /var/cache/apk/*

WORKDIR /usr/src

RUN git clone https://github.com/jacksonliam/mjpg-streamer.git mjpeg-streamer \
 && cd mjpeg-streamer/mjpg-streamer* \
 && git checkout $TAG \
 && make \
 && make install

FROM alpine:latest 

RUN apk update \
 && apk upgrade \
 && apk add --no-cache --update musl shadow jpeg raspberrypi v4l-utils-libs \
 && rm -rf /var/cache/apk/*

COPY --from=prep /usr/local/lib/mjpg-streamer /usr/local/lib/mjpg-streamer
COPY --from=prep /usr/local/share/mjpg-streamer/www /usr/local/share/mjpg-streamer/www
COPY --from=prep /usr/local/share/mjpg-streamer/www /usr/local/share/mjpg-streamer/www


