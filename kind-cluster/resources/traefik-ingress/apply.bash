#!/bin/bash
set -eux

WORK_DIR=$(pwd)
SCRIPT_DIR=$(cd $(dirname $0); pwd)

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
# apply metallb.

helm repo add metallb https://metallb.github.io/metallb
helm repo update
helm install \
  metallb \
  metallb/metallb \
  --create-namespace --namespace traefik-ingress \
  --version 0.14.9 \
  -f ${SCRIPT_DIR}/metallb-values.yaml

kubectl wait -A --for=condition=available deployment --all --timeout=90s

kubectl apply \
  --namespace traefik-ingress \
  -f ${SCRIPT_DIR}/metallb-resources.yaml

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
# apply traefik.

helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install \
  traefik \
  traefik/traefik \
  --create-namespace --namespace traefik-ingress \
  --version 35.2.0 \
  -f ${SCRIPT_DIR}/traefik-values.yaml

kubectl wait -A --for=condition=available deployment --all --timeout=90s
