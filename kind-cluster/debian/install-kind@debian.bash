#!/bin/bash
set -eux

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
# variables.
#
USER_NAME=${USER_NAME:-${SUDO_USER:-'debian'}}
PROXY_URL=${PROXY_URL:-''}
NO_PROXY_URL=${NO_PROXY_URL:-''}

VELERO_VER=${VELERO_VER:-'v1.16.0'}
KIND_VER=${KIND_VER:-'v0.29.0'}

LOG_LEVEL=${LOG_LEVEL:-'INFO'}

WORK_DIR=$(pwd)
SCRIPT_DIR=$(cd $(dirname $0); pwd)

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
# utilities.
#
utils() {
  function logger() {
    echo -e "[\033[1;$1\033[00m] $(date '+%Y-%m-%d %H:%M:%S.%3N'): ${@:2}"
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
# main
#

#
# Check arguments.
#
if [ -z "$(cat /etc/passwd | grep ^$USER_NAME:)" ]; then
  utils;error "Invalid argument (\`USER_NAME\`). \`$USER_NAME\` user is NOT exist."
  exit 1
fi

#
# Proxy configurations.
#
if [ -n "$PROXY_URL" ]; then
  # Environment variables.
  if [ ! -e /etc/profile.d/proxy.sh ]; then
    cat <<EOF >/etc/profile.d/proxy.sh
export http_proxy=$PROXY_URL
export https_proxy=$PROXY_URL
export no_proxy=$NO_PROXY_URL
EOF
    source /etc/profile.d/proxy.sh
  fi

  # for APT
  if [ ! -e /etc/apt/apt.conf.d/proxy.conf ]; then
    echo "Acquire::http::Proxy \"$PROXY_URL\";" >> /etc/apt/apt.conf.d/proxy.conf
    echo "Acquire::https::Proxy \"$PROXY_URL\";" >> /etc/apt/apt.conf.d/proxy.conf
  fi
fi

#
# Manage sudo and sudoers.
#
if ! command -v sudo 2>&1 >/dev/null; then
  utils;warn '`sudo` is NOT found.'

  if [ $(id -u) -ne 0 ]; then
    utils;error "You need to be root to run this script."
    exit 1
  fi

  sed -ie 's/^deb cdrom/# deb cdrom/g' /etc/apt/sources.list

  #
  # Install sudo.
  #
  apt update && apt upgrade && apt install -y --no-install-recommends \
    sudo

  #
  # add the user to sudoers.
  #
  if [ -z "$(cat /etc/group | grep ^sudo: | grep $USER_NAME)" ]; then
    /usr/sbin/usermod -aG sudo $USER_NAME
  fi
fi

#
# Install dependencies if not exits.
#
apt update && apt upgrade && apt install -y --no-install-recommends \
  curl \
  ca-certificates \
  bash-completion

# create the bash_completion.d directory.
mkdir -p /etc/bash_completion.d

#
# Install docker-ce if not exists.
#
if ! command -v docker 2>&1 >/dev/null; then
  # Add Docker's official GPG key:
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc

  # Add the repository to Apt sources:
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null

  utils;info 'Install docker-ce'
  apt update && apt install -y --no-install-recommends \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

  # Proxy configuration.
  if [ -n "$PROXY_URL" ]; then
    mkdir -p /etc/systemd/system/docker.service.d
    cat <<EOF >/etc/systemd/system/docker.service.d/proxy.conf
[Service]
Environment="HTTP_PROXY=$PROXY_URL"
Environment="HTTPS_PROXY=$PROXY_URL"
EOF
    systemctl daemon-reload
    systemctl restart docker
  fi

  # Add the user to the docker group.
  /usr/sbin/usermod -aG docker $USER_NAME
fi

#
# Install kubectl if not exists.
#
if ! command -v kubectl 2>&1 >/dev/null; then
  utils;info 'Install kubectl'
  curl -fsSL -o /usr/local/bin/kubectl https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$(dpkg --print-architecture)/kubectl
  chmod +x /usr/local/bin/kubectl
  kubectl completion bash >/etc/bash_completion.d/kubectl
fi

#
# Install helm if not exists.
#
if ! command -v helm 2>&1 >/dev/null; then
  utils;info 'Install helm'
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  helm completion bash >/etc/bash_completion.d/helm
fi

#
# Install velero if not exists.
#
if ! command -v velero 2>&1 >/dev/null; then
  utils;info 'Install velero'
  curl -fsSL https://github.com/vmware-tanzu/velero/releases/download/$VELERO_VER/velero-$VELERO_VER-linux-$(dpkg --print-architecture).tar.gz | tar zxv -C /usr/local/bin/ --strip=1 --wildcards '*/velero'
  velero completion bash >/etc/bash_completion.d/velero
fi

#
# Install kind if not exists.
#
if ! command -v kind 2>&1 >/dev/null; then
  utils;info 'Install kind'
  curl -fsSL -o /usr/local/bin/kind https://kind.sigs.k8s.io/dl/$KIND_VER/kind-linux-$(dpkg --print-architecture)
  chmod +x /usr/local/bin/kind
  kind completion bash >/etc/bash_completion.d/kind
fi
