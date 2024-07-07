#! /usr/bin/bash
OVPN_PORT="443"
OVPN_PROTO="udp"
IF_TUN="tun0"
IF_LAN="enp0s8"
IF_GW_TUN="10.8.0.1"
IF_GW_LAN="192.168.1.254"
NET_TUN="10.8.0.0/24"
NET_LAN="192.168.1.0/24"
IP_LAN="192.168.1.3"
ALLOW_PORT="80,443"

## Changement de strategie, je passe sur une approche restrictive.
## Les redirections sont donc rejetes par defaut.
vim -O /etc/ufw/before.rules INFO/BEFORE_UFW
vim -O /etc/default/ufw INFO/DEFAULT_UFW

# On autorise les connexion au serveur VPN
ufw allow in on enp0s8 proto $OVPN_PROTO to $IP_LAN port $OVPN_PORT
# On autorise les connexion au serveur SSH depuis la LAN
ufw allow in on enp0s8 proto tcp from 192.168.1.0/24 port 22
# On isole l'interface du VPN
ufw deny out on $IF_TUN
ufw deny in on $IF_TUN

# on ouvre les ports 80,443 (I/O)
ufw allow in on $IF_TUN proto tcp to any port $ALLOW_PORT
ufw allow out on $IF_TUN proto tcp to any port $ALLOW_PORT

# on active la redirection du vpn vers l'interface LAN
ufw route allow in on $IF_TUN out on $IF_LAN proto tcp to any port $ALLOW_PORT
ufw route allow in on $IF_LAN out on $IF_TUN proto tcp to any port $ALLOW_PORT

# on bloque l'access au reseau VPN depuis la LAN
ufw deny in from $NET_LAN proto tcp port $ALLOW_PORT
# Et inversement
ufw deny out to $NET_LAN proto tcp port $ALLOW_PORT

# on autorise malgres tout l'access a la WAN
ufw allow out to $IF_GW_LAN proto tcp port $ALLOW_PORT

echo "Redemarrage du pare-feu..."
ufw disable
ufw enable
echo "Affichage des regles du pare-feu:"
ufw status

#### Enable forwarding for IPV4
vim -O /etc/sysctl.conf INFO/SYSCTL
echo "Rechargement des parametres du kernel..."
sysctl --system
