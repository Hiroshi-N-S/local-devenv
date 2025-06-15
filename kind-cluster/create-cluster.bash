#!/bin/bash
set -eux

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
# variables.

K8S_DOMAIN=${K8S_DOMAIN:-'k8s-cluster'}
CERT_FILE_NAME=${CERT_FILE_NAME:-'local-devenv'}

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

K8S_DOMAIN=$K8S_DOMAIN CERT_FILE_NAME=$CERT_FILE_NAME bash $SCRIPT_DIR/../certs/generate-certs.bash

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
# Create a kind cluster.

kind create cluster --config config/kind-cluster.yaml
kubectl wait -A --for=condition=available deployment --all --timeout=90s

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
