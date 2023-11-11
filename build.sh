#!/bin/bash -e

#export IMAGE=quay.io/kairos/kairos-ubuntu-22-lts:v2.4.1-k3sv1.27.3-k3s1
export IMAGE=docker.io/ianblenke/kairos-ubuntu-22-lts:latest

DOCKER_BUILDKIT=1 docker build . --secret id=pro-attach-config,src=pro-attach-config.yaml -t ianblenke/kairos-ubuntu-22-lts -t $IMAGE
docker push ianblenke/kairos-ubuntu-22-lts

