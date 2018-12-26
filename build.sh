#!/bin/bash


GITHUB_REPO="jacksonliam/mjpg-streamer"
TAG_BASE="pborky/mjpeg-streamer"

get_latest() {
  curl --silent https://api.github.com/repos/$1/releases/latest | 
  grep '"tag_name":' | 
  sed -E 's/.*"([^"]+)".*/\1/'
}

if [ -z "$1" ]; then
  if [ ! -z "$GITHUB_REPO" ]; then 
    TAG=$(get_latest "$GITHUB_REPO")
  fi
  echo TAG: $TAG
  if [ -z "$TAG" ]; then 
    TAG="master"
  fi
  echo "TAG: $TAG (latest)"
  docker build . --tag=$TAG_BASE --build-arg "tag=$TAG"
  docker build . --tag=$TAG_BASE:$TAG --build-arg "tag=$TAG"
else
  TAG=$1
  echo "TAG: $TAG"
  docker build . --tag=$TAG_BASE:$TAG --build-arg "tag=$TAG"
fi
