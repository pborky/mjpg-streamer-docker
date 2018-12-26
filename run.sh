#!/bin/bash

docker run --rm -it --device /dev/vchiq -p 127.0.0.1:8080:8080  pborky/mjpeg-streamer

