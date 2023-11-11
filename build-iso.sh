#!/bin/bash -e

#export IMAGE=quay.io/kairos/kairos-ubuntu-22-lts:v2.4.1-k3sv1.27.3-k3s1
export IMAGE=docker.io/ianblenke/kairos-ubuntu-22-lts:latest

CTR="sudo ctr"
DOCKER=docker
DOCKERSOCK=/var/run/docker.sock
if which nerdctl; then
  DOCKER="sudo nerdctl"
  mkdir -p /run/containerd
  ln -nsf /run/k3s/containerd/containerd.sock /run/containerd/containerd.sock
  DOCKERSOCK=/run/k3s/containerd/containerd.sock
fi

if which $DOCKER; then
  $DOCKER pull $IMAGE
  $DOCKER run -v $PWD/cloud_init.yaml:/cloud_init.yaml \
              -v $PWD/build:/tmp/auroraboot \
              -v $DOCKERSOCK:/var/run/docker.sock \
  	      --network=host \
              --rm -ti quay.io/kairos/auroraboot \
              --set container_image=docker://$IMAGE \
              --set "disable_http_server=true" \
              --set "disable_netboot=true" \
              --cloud-config /cloud_init.yaml \
              --set "state_dir=/tmp/auroraboot"
else
  if which ${CTR}; then
    ${CTR} image pull $IMAGE
    ${CTR} image pull quay.io/kairos/auroraboot:latest
    ${CTR} run --rm \
	    --tty \
            --net-host \
            --mount type=bind,src=$PWD/cloud_init.yaml,dst=/cloud_init.yaml,options=rbind:ro \
            --mount type=bind,src=$PWD/build,dst=/tmp/auroraboot,options=rbind:rw \
	    --mount type=bind,src=/run/k3s/containerd/containerd.sock,dst=/var/run/docker.sock,options=bind:rw \
            quay.io/kairos/auroraboot:latest \
	    auroraboot \
	    /usr/bin/auroraboot \
            --set container_image=$IMAGE \
            --set "disable_http_server=true" \
            --set "disable_netboot=true" \
            --cloud-config /cloud_init.yaml \
            --set "state_dir=/tmp/auroraboot"
   else
    echo "No docker/nerdctl or ctr runtime"
    exit 1
  fi
fi

#docker run -v "$PWD"/build:/tmp/auroraboot -v /var/run/docker.sock:/var/run/docker.sock --rm -ti quay.io/kairos/auroraboot --set container_image=docker://ianblenke/kairos-ubuntu-22-lts --set "disable_http_server=true" --set "disable_netboot=true" --set "state_dir=/tmp/auroraboot"
