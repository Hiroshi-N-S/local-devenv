#!/bin/bash
set -eux

K8S_DOMAIN=${K8S_DOMAIN:-'k8s-cluster'}
CERT_FILE_NAME=${CERT_FILE_NAME:-'local-devenv'}

WORK_DIR=$(pwd)
SCRIPT_DIR=$(cd $(dirname $0); pwd)

cd ${SCRIPT_DIR}

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
