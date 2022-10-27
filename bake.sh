#!/bin/bash

env_file=env.hcl
BUILDER_NAME=multiarch
BAKE_ARGS=""
default_platform=linux/arm/v7
COPY_CERTS=0
default_hcl=docker-bake.hcl
force_push=0

for arg in "$@"; do
  case "$arg" in
    --env=*) 
        env_file="${arg#*=}"
        ;;
    --builder=*) 
        BUILDER_NAME="${arg#*=}"
        ;;
    --copy-ca-certs)
        COPY_CERTS=1
        ;;
    --targets=*) 
        targets="${arg#*=}"
        ;;
    --platform=*)
        platform="${arg#*=}"
        ;;
    --hcl=*)
        hcl="${arg#*=}"
        ;;
    --push)
        force_push=1
        ;;
    --progress=*)
        progress="${arg}"
        ;;
    --print | --load | --pull | --no-cache | --set*)
        BAKE_ARGS="$BAKE_ARGS $arg"
        ;;
    *)
        test "${arg}" != "--help" -a "${arg}" != "-h"  && printf "ERROR: unexpected argument: \"$arg\"\n"
        printf "\nUsage: $(basename $0) [OPTS]\n"
        printf "\nwhere [OPTS] can be:\n"
        printf "\t--env=[env file]  -  name of env file to source, default: env.hcl\n"
        printf "\t--builder=[name]  - name of builder to create (if not exists) and use, default: multiarch\n"
        printf "\t--targets=[list of targets]  - list of targets to build\n\n"
        printf "\tNote: In case the local git contains changes only a \"dev\" target is built\n"
        printf "\t      for a single arch \"linux/386\" with docker image tag of \"dev-DIRTY\".\n"
        exit 
        ;;
    esac
done

# source and export env variables
set -a
test -e $env_file && source $env_file

set -ex

if ! docker buildx ls | grep ^$BUILDER_NAME -c > /dev/null 2>&1; then

    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
    docker run --privileged --rm tonistiigi/binfmt --install all

    DRIVER_OPTS=""
    if [ -n "${PKG_PROXY_NET}" ]
    then DRIVER_OPTS="--driver-opt network=${PKG_PROXY_NET}"
    fi
    if [ -n "${PKG_PROXY}" ]
    then DRIVER_OPTS="$DRIVER_OPTS --driver-opt env.http_proxy=${PKG_PROXY} --driver-opt env.https_proxy=${PKG_PROXY}"
    else if [ -n "$http_proxy" ]
         then DRIVER_OPTS="$DRIVER_OPTS --driver-opt env.http_proxy=${http_proxy} --driver-opt env.https_proxy=${http_proxy}"
         fi
    fi
    docker buildx create --name $BUILDER_NAME --node $BUILDER_NAME --use --driver docker-container $DRIVER_OPTS
    docker buildx inspect --bootstrap

    if [ "$COPY_CERTS" = "1" ]
    then docker cp /etc/ssl/certs/ buildx_buildkit_multiarch:/etc/ssl/
         docker exec -it buildx_buildkit_multiarch c_rehash -v
    fi
fi
# override env variables
BUILD_DATE="$(date +%Y%m%d)"
if [ -n "$(git status -s)" ]; then
  GIT_BRANCH=DIRTY 
else 
  GIT_BRANCH=$(git rev-parse --short HEAD)
fi

if [ "${force_push}" -eq 0 ] && [ -z "${GIT_BRANCH}" -o "${GIT_BRANCH}" == "DIRTY" ]; then
  if [ -z "$targets" ]
  then targets=dev
   fi
  if [ -z "$progress" ]
  then progress="--progress=plain"
  fi
  BAKE_ARGS="$BAKE_ARGS ${progress} --load --set *.platform=${platform:-${default_platform}} $targets"
else
  if [ -n "$platform" ]; then
    BAKE_ARGS="$BAKE_ARGS --set *.platform=${platform}"
  fi
  BAKE_ARGS="$BAKE_ARGS --push $progress $targets"
fi

docker buildx bake -f ${hcl:-${default_hcl}} $BAKE_ARGS
