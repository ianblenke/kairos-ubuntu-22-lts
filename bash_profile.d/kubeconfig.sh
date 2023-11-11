#!/bin/bash
#
# Grab the k3s KUBECONFIG for whichever user is logging in.
#
if [ ! -f ~/.kube/config ]; then
	mkdir -p ~/.kube/config
	sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config
fi
export KUBECONFIG=~/.kube/config
