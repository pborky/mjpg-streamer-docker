#!/bin/bash


GITHUB_REPO="foosel/OctoPrint"

get_latest() {
  curl --silent https://api.github.com/repos/$1/releases/latest | 
  grep '"tag_name":' | 
  sed -E 's/.*"([^"]+)".*/\1/'
}

if [ -z "$1" ]; then
  if [ ! -z "$GITHUB_REPO" ]; then 
    TAG=$(get_latest "foosel/OctoPrint")
  fi
  if [ -z "$TAG" ]; then 
    TAG="master"
  fi
  echo "TAG: $TAG (latest)"
  docker build . --tag=octoprint --build-arg "tag=$TAG"
  docker build . --tag=octoprint:$TAG --build-arg "tag=$TAG"
else
  TAG=$1
  echo "TAG: $TAG"
  docker build . --tag=octoprint:$TAG --build-arg "tag=$TAG"
fi
