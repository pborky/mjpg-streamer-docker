#!/bin/sh
export LD_LIBRARY_PATH="/opt/vc/lib/:/usr/local/lib/mjpeg_streamer"
/usr/local/bin/mjpg_streamer -o "output_http.so -w /usr/local/share/mjpg-streamer/www" -i "input_raspicam.so -x 800 -y 600 -fps 10 -vf -vs -rot 0"
