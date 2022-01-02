

# Prepare 

```{bash}
cat > .env <<-EOF
# for raspberry pi
TARGET_ARCH=arm32v6
QEMU_ARCH=arm

# git tag to build
TAG=v1.0.0

# container config
proxy_network=external_network_of_your_choice
registry_host=registry_of_your_choice

# groups for container user based on host gids
$(./getgid.py)
EOF
```

# Build
```{bash}
# build
docker-compose -f docker-compose-build.yml build
# push to docker registry (optional)
docker-compose -f docker-compose-build.yml push
# start the service
docker-compose up -d
```


