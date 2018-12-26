#!/bin/bash

docker run --name mjpeg-streamer -d --restart unless-stopped -it --device /dev/vchiq -p 127.0.0.1:8080:8080  pborky/mjpeg-streamer $@


