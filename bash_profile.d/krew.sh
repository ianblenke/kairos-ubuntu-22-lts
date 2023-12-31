#!/bin/bash
#
# Install krew and stern
#
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
which kubectl-krew > /dev/null 2>&1 || (
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)
which kubectl-stern > /dev/null 2>&1 || kubectl krew install stern
ln -s kubectl-stern ${KREW_ROOT:-$HOME/.krew}/bin/stern
ln -s kubectl-krew ${KREW_ROOT:-$HOME/.krew}/bin/krew

