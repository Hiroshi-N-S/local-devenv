#!/bin/bash
set -eux

NAS_DOMAIN=${NAS_DOMAIN:-'synology-nas'}

CERT_FILE_NAME=${CERT_FILE_NAME:-'local-devenv'}

COUNTRY_NAME=${COUNTRY_NAME:-'JP'}
STATE_NAME=${STATE_NAME:-'Osaka'}
LOCALITY_NAME=${LOCALITY_NAME:-'Osaka'}
ORGANIZATION_NAME=${ORGANIZATION_NAME:-'Personal'}

WORK_DIR=$(pwd)
SCRIPT_DIR=$(cd $(dirname $0); pwd)

if [ -e $SCRIPT_DIR/$CERT_FILE_NAME.crt ]; then
  exit 0
fi

# Remove old files.
(
  cd $SCRIPT_DIR && ls | grep -ivE "$(basename $0)" | xargs rm -rf
)

# Generate a Server Certificate.

## Generate a private key.
openssl genrsa -out $SCRIPT_DIR/$CERT_FILE_NAME.key 4096

## Generate the certificate.
openssl req -x509 -new -nodes -sha512 -days 3650 \
  -subj "/C=$COUNTRY_NAME/ST=$STATE_NAME/L=$LOCALITY_NAME/O=$ORGANIZATION_NAME/CN=$NAS_DOMAIN.local" \
  -key $SCRIPT_DIR/$CERT_FILE_NAME.key \
  -out $SCRIPT_DIR/$CERT_FILE_NAME.crt

## Generate a Certificate Signing Request (CSR).
openssl req -new -sha512 \
  -subj "/C=$COUNTRY_NAME/ST=$STATE_NAME/L=$LOCALITY_NAME/O=$ORGANIZATION_NAME/CN=$NAS_DOMAIN.local" \
  -key $SCRIPT_DIR/$CERT_FILE_NAME.key \
  -out $SCRIPT_DIR/$CERT_FILE_NAME.csr

## Generate an x509 v3 extension file.
if [ ! -e $SCRIPT_DIR/v3.ext ]; then
  cat <<EOF >$SCRIPT_DIR/v3.ext
authorityKeyIdentifier  = keyid,issuer
basicConstraints        = CA:FALSE
keyUsage                = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage        = serverAuth
subjectAltName          = @alt_names

[alt_names]
DNS.1                   = $NAS_DOMAIN.local
EOF
fi

## Generate a Self-Signed Certificate with the `v3.ext`.
openssl x509 -req -sha512 -days 3650 \
  -extfile $SCRIPT_DIR/v3.ext \
  -CA $SCRIPT_DIR/$CERT_FILE_NAME.crt -CAkey $SCRIPT_DIR/$CERT_FILE_NAME.key -CAcreateserial \
  -in $SCRIPT_DIR/$CERT_FILE_NAME.csr \
  -out $SCRIPT_DIR/$CERT_FILE_NAME.crt

# Convert `.crt`` to `.cert`, for use by Docker.
openssl x509 -inform PEM \
  -in $SCRIPT_DIR/$CERT_FILE_NAME.crt \
  -out $SCRIPT_DIR/$CERT_FILE_NAME.cert

openssl x509 -outform PEM \
  -in $SCRIPT_DIR/$CERT_FILE_NAME.crt \
  -out $SCRIPT_DIR/$CERT_FILE_NAME.pem
