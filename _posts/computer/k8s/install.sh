#!/bin/bash
set -e  # 遇到错误立即退出

#curl -LO https://dl.k8s.io/release/v1.35.0/bin/linux/amd64/kubeadm

install -o root -g root -m 0755 kubeadm /usr/local/bin/kubeadm

curl -LO https://dl.k8s.io/release/v1.35.0/bin/linux/amd64/kubelet

install -o root -g root -m 0755 kubelet /usr/local/bin/kubelet

curl -LO https://dl.k8s.io/release/v1.35.0/bin/linux/amd64/kubectl

install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

curl -LO https://dl.k8s.io/release/v1.35.0/bin/linux/amd64/kubectl-convert
install -o root -g root -m 0755 kubectl-convert /usr/local/bin/kubectl-convert

apt-get install -y bash-completion


## docker
## https://docs.docker.com/engine/install/debian/
#  apt update
#  apt install ca-certificates curl
#  install -m 0755 -d /etc/apt/keyrings
#  curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
#  chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
#  tee /etc/apt/sources.list.d/docker.sources <<EOF
# Types: deb
# URIs: https://download.docker.com/linux/debian
# Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
# Components: stable
# Signed-By: /etc/apt/keyrings/docker.asc
# EOF

#  apt update

apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin


systemctl status docker

systemctl start docker

systemctl enable docker

