#!/bin/bash
set -eux

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
# variables.

K8S_DOMAIN=${K8S_DOMAIN:-'k8s-cluster'}
NAS_DOMAIN=${NAS_DOMAIN:-'synology-nas'}
CERT_FILE_NAME=${CERT_FILE_NAME:-'local-devenv'}

PRIVATE_REGISTRY_DOMAIN=${PRIVATE_REGISTRY_DOMAIN:-"$NAS_DOMAIN.local"}
PRIVATE_REGISTRY_IP=${PRIVATE_REGISTRY_IP:-''}
PRIVATE_REGISTRY_PORT=${PRIVATE_REGISTRY_PORT:-'8443'}

KIND_CLUSTER_NAME=${KIND_CLUSTER_NAME:-'kind-cluster'}

LOG_LEVEL=${LOG_LEVEL:-'INFO'}

WORK_DIR=$(pwd)
SCRIPT_DIR=$(cd $(dirname $0); pwd)

cd ${SCRIPT_DIR}

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
# utilities.

utils() {
  function logger() {
    echo -e "[\033[1;$1\033[00m] $(date '+%Y-%m-%d %H:%M:%S.%3N'): ${@:2}"
  }

  function msg() {
    echo -e "\033[32m > $@ \033[m"
  }

  function debug() {
    if [[ "$LOG_LEVEL" =~ ^(DEBUG)$ ]]; then
      logger "44m DEBUG " $@
    fi
  }

  function info() {
    if [[ "$LOG_LEVEL" =~ ^(DEBUG|INFO)$ ]]; then
      logger "42m INFO  " $@
    fi
  }

  function warn() {
    if [[ "$LOG_LEVEL" =~ ^(DEBUG|INFO|WARN)$ ]]; then
      logger "43m WARN  " $@
    fi
  }

  function error() {
    if [[ "$LOG_LEVEL" =~ ^(DEBUG|INFO|WARN|ERROR)$ ]]; then
      logger "41m ERROR " $@
    fi
  }
}

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
# Generate a Cluster Certificate.

K8S_DOMAIN=$K8S_DOMAIN NAS_DOMAIN=$NAS_DOMAIN CERT_FILE_NAME=$CERT_FILE_NAME bash $SCRIPT_DIR/../certs/generate-certs.bash

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
# Configure Docker to use the private registry.

# add host in the `/etc/hosts` file if not exists.
ACTUAL_PRIVATE_REGISTRY_IP=$(sudo ping -c 1 $PRIVATE_REGISTRY_DOMAIN  2>/dev/null | sed -nE 's/^PING[^(]+\(([^)]+)\).*/\1/p')
if [ -z "$ACTUAL_PRIVATE_REGISTRY_IP"]; then
  if [ -z "$(grep $PRIVATE_REGISTRY_DOMAIN /etc/hosts)" ]; then
    while [ -z "$(sudo ping -c 1 $PRIVATE_REGISTRY_IP | grep '1 received')" ]; do
      utils;msg 'Enter ip address of your private container registry: '
      read PRIVATE_REGISTRY_IP
    done

    sudo bash -c "echo '$PRIVATE_REGISTRY_IP  $PRIVATE_REGISTRY_DOMAIN' >>/etc/hosts"
  fi
else
  PRIVATE_REGISTRY_IP=$ACTUAL_PRIVATE_REGISTRY_IP
fi

# Provide the certificates to Docker.
DOCKER_CERTS_DIR=/etc/docker/certs.d
PRIVATE_REGISTRY_CERTS_DIR=$DOCKER_CERTS_DIR/$PRIVATE_REGISTRY_DOMAIN:$PRIVATE_REGISTRY_PORT
if [ ! -e $PRIVATE_REGISTRY_CERTS_DIR/$CERT_FILE_NAME.cert ]; then
  if [ ! -d $PRIVATE_REGISTRY_CERTS_DIR ]; then
    sudo bash -c "mkdir -p $PRIVATE_REGISTRY_CERTS_DIR"
  fi

  exts=("key" "crt" "cert")
  for ext in ${exts[@]}; do
    sudo bash -c "cp $SCRIPT_DIR/../certs/$CERT_FILE_NAME.$ext $PRIVATE_REGISTRY_CERTS_DIR"
  done
fi

# Log into the private registry from the Docker client.
docker login $PRIVATE_REGISTRY_DOMAIN:$PRIVATE_REGISTRY_PORT

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
# Create a kind cluster.

cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: $KIND_CLUSTER_NAME
nodes:
  - role: control-plane
    image: kindest/node:v1.32.5
    extraPortMappings:
      # Ingress
      - containerPort: 30080
        hostPort: 80
        protocol: TCP
      - containerPort: 30443
        hostPort: 443
        protocol: TCP
    extraMounts:
      # Mount a Docker config.json file containing credential on the host into each kind node.
      - containerPath: /var/lib/kubelet/config.json
        hostPath: $HOME/.docker/config.json
        readOnly: true
      # Mount both certificates and keys on the host directory into the `containerd` plugin patching the default configuration
      - containerPath: /etc/containerd/certs.d
        hostPath: /etc/docker/certs.d
        readOnly: true
# NOTE: the following patch is not necessary with images from kind v0.27.0+
# It may enable some older images to work similarly
containerdConfigPatches:
  - |-
    [plugins."io.containerd.grpc.v1.cri".registry]
      config_path = "/etc/containerd/certs.d"
EOF
kubectl wait -A --for=condition=available deployment --all --timeout=90s

# add host in the control-plane's `/etc/hosts` file.
docker exec -it $KIND_CLUSTER_NAME-control-plane bash -c "echo '$PRIVATE_REGISTRY_IP  $PRIVATE_REGISTRY_DOMAIN' >>/etc/hosts"

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
# Apply traefik-ingress.

kubectl create namespace traefik-ingress
kubectl create secret tls \
  traefik-tls-secret \
  --namespace traefik-ingress \
  --key  $SCRIPT_DIR/../certs/$CERT_FILE_NAME.key \
  --cert $SCRIPT_DIR/../certs/$CERT_FILE_NAME.crt

bash $SCRIPT_DIR/resources/traefik-ingress/apply.bash

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
# Apply Argo CD.

kubectl create namespace argo-cd
kubectl create secret tls \
  sso-tls-secret \
  --namespace argo-cd \
  --key  $SCRIPT_DIR/../certs/$CERT_FILE_NAME.key \
  --cert $SCRIPT_DIR/../certs/$CERT_FILE_NAME.crt

bash $SCRIPT_DIR/resources/argo-cd/apply.bash
