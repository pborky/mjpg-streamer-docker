#!/bin/bash

GITHUB_REPO="jacksonliam/mjpg-streamer"
TAG_BASE="pborky/mjpeg-streamer"
# new unprivileged user
NEW_UID=666
NEW_GID=666
NEW_USER=mjpeg_streamer
# groups of the new user, comma sepparated list
NEW_GROUPS="video"

# get latest repository form github
get_latest() {
  curl --silent https://api.github.com/repos/$1/releases/latest |
  grep '"tag_name":' |
  sed -E 's/.*"([^"]+)".*/\1/'
}

# get gids of groups
get_gid() {
  for grp in ${NEW_GROUPS//,/ }; do
    echo -n "$(cut -d: -f3 < <(getent group $grp)),"
  done
}
# get the group ids
GIDS=$(get_gid $NEW_GROUPS)
# create new user
#if ! id $NEW_USER; then
#  groupadd -g $NEW_GID $NEW_USER
#  useradd -rNM -s /bin/bash -g $NEW_USER -u $NEW_UID $NEW_USER
#fi

if [ -z "$1" ]; then
  # try to get latest branch
  if [ ! -z "$GITHUB_REPO" ]; then
    TAG=$(get_latest "$GITHUB_REPO")
  fi
  # fallback
  if [ -z "$TAG" ]; then
    TAG="master"
  fi
  echo "TAG: $TAG (latest)"
  docker build . --tag=$TAG_BASE \
          --build-arg tag=$TAG \
          --build-arg gids=$GIDS \
          --build-arg uid=$NEW_UID \
          --build-arg gid=$NEW_GID \
          --build-arg user=$NEW_USER
  docker build . --tag=$TAG_BASE:$TAG \
          --build-arg tag=$TAG \
          --build-arg gids=$GIDS \
          --build-arg uid=$NEW_UID \
          --build-arg gid=$NEW_GID \
          --build-arg user=$NEW_USER
else
  TAG=$1
  echo "TAG: $TAG"
  docker build . --tag=$TAG_BASE:$TAG \
          --build-arg tag=$TAG \
          --build-arg gids=$GIDS \
          --build-arg uid=$NEW_UID \
          --build-arg gid=$NEW_GID \
          --build-arg user=$NEW_USER
fi

