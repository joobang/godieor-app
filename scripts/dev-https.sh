#!/bin/sh
# Usage: scripts/dev-https.sh <mac-private-lan-ipv4>
set -eu
if [ "$#" -ne 1 ]; then echo "Usage: $0 <Mac private LAN IPv4>" >&2; exit 2; fi
LAN_IP="$1"
case "$LAN_IP" in *[!0-9.]*|'') echo 'Provide a numeric IPv4 address' >&2; exit 2;; esac
openssl_bin="$(command -v openssl)"
CERT_DIR="${TMPDIR:-/private/tmp}/godieor-dev-https-${LAN_IP}"
mkdir -p "$CERT_DIR"
chmod 700 "$CERT_DIR"
if [ ! -f "$CERT_DIR/ca.pem" ]; then
  "$openssl_bin" req -x509 -newkey rsa:3072 -nodes -sha256 -days 30 \
    -subj '/CN=GODIEOR Local Dev CA' -addext 'basicConstraints=critical,CA:TRUE' \
    -keyout "$CERT_DIR/ca.key" -out "$CERT_DIR/ca.pem" >/dev/null 2>&1
  "$openssl_bin" req -new -newkey rsa:2048 -nodes -sha256 \
    -subj '/CN=GODIEOR Local Dev' -keyout "$CERT_DIR/server.key" \
    -out "$CERT_DIR/server.csr" >/dev/null 2>&1
  printf 'subjectAltName=IP:%s\nextendedKeyUsage=serverAuth\nbasicConstraints=CA:FALSE\n' "$LAN_IP" > "$CERT_DIR/server.ext"
  "$openssl_bin" x509 -req -sha256 -days 14 -in "$CERT_DIR/server.csr" \
    -CA "$CERT_DIR/ca.pem" -CAkey "$CERT_DIR/ca.key" -CAcreateserial \
    -extfile "$CERT_DIR/server.ext" -out "$CERT_DIR/server.pem" >/dev/null 2>&1
  "$openssl_bin" x509 -in "$CERT_DIR/ca.pem" -outform DER -out "$CERT_DIR/godieor-dev-ca.cer"
  chmod 600 "$CERT_DIR"/*.key
fi
printf 'Install and trust CA on test iPhone: %s/godieor-dev-ca.cer\n' "$CERT_DIR"
exec python3 "$(dirname "$0")/dev-https.py" --ip "$LAN_IP" --cert "$CERT_DIR/server.pem" --key "$CERT_DIR/server.key"
