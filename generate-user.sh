#! /usr/bin/bash

set -e

SERVER_CONFIG_DIR="/etc/openvpn"
CLIENT_CONFIG_DIR="$HOME/projet.git/authority-easy-rsa/"

# ca cert and tls-auth key
CA_CERT=$(sudo cat ${SERVER_CONFIG_DIR}/ca.crt)
TA_KEY=$(sudo cat ${SERVER_CONFIG_DIR}/ta.key)

# This could be anywhere and have whatever you want in it.
BASE_CONFIG=$(cat ${CLIENT_CONFIG_DIR}/client-base.conf)

USER=$1

CLIENT_CERT_FILE="${CLIENT_CONFIG_DIR}/clients/vpn/${USER}.crt"
CLIENT_KEY_FILE="${CLIENT_CONFIG_DIR}/clients/vpn/${USER}.key"

# Dump it all to a `.ovpn` configuration file.
CLIENT_CERT=$(openssl x509 -in ${CLIENT_CERT_FILE} -outform pem)
CLIENT_KEY=$(cat ${CLIENT_KEY_FILE})

# Generate the config file.
cat <<EOF > "${CLIENT_CONFIG_DIR}/clients/vpn/${USER}.ovpn"

## Base configuration
${BASE_CONFIG}

## PKI BEGIN
<ca>
${CA_CERT}
</ca>
<cert>
${CLIENT_CERT}
</cert>
<key>
${CLIENT_KEY}
</key>
<tls-crypt>
${TA_KEY}
</tls-crypt>

## PKI END

EOF

su -c "google-authenticator -t -d -r3 -R30 -f -W -e5 -l 'VPN ${USER}' -s /etc/openvpn/gauth/${USER}" gauth
