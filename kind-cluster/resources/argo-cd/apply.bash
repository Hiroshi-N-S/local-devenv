#!/bin/bash
set -eux

WORK_DIR=$(pwd)
SCRIPT_DIR=$(cd $(dirname $0); pwd)

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
# apply argo-cd.

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install \
  argo-cd \
  argo/argo-cd \
  --create-namespace --namespace argo-cd \
  --version 7.7.23 \
  -f ${SCRIPT_DIR}/values.yaml

kubectl wait -A --for=condition=available deployment --all --timeout=90s
