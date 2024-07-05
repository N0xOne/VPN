#! /usr/bin/bash
OVPN_PORT="443"
OVPN_PROTO="udp"
IF_TUN="tun0"
IF_LAN="enp0s8"
NET_TUN="10.8.0.0/24"
NET_LAN="192.168.1.0/24"
ALLOW_PORT="80,443"

vim -O /etc/ufw/before.rules INFO/BEFORE_UFW
vim -O /etc/default/ufw INFO/DEFAULT_UFW

ufw allow in on $IF_LAN proto $OVPN_PROTO to any port $OVPN_PORT comment "Accept OpenVPN port"
ufw deny in on $IF_LAN proto $OVPN_PROTO to any port $OVPN_PORT from $NET_LAN comment "Deny OpenVPN from lan"
ufw deny in on $IF_TUN from $NET_TUN comment "Deny all traffic inside TUN"
ufw deny in on $IF_TUN to $NET_TUN comment "Deny all traffic inside TUN"
ufw allow in on $IF_TUN to any proto tcp port $ALLOW_PORT from $NET_TUN comment "Allow HTTP(S) traffic inside TUN"
#ufw route allow in on enp0s8 out on tun0 to $NET_TUN port $ALLOW_PORT from $NET_LAN comment "OpenVPN Forwarding from LAN"
ufw route allow in on $IF_TUN out on $IF_LAN to any proto tcp port $ALLOW_PORT from $NET_TUN comment "OpenVPN Forwarding from TUN"

echo "Redemarrage du pare-feu..."
ufw disable
ufw enable
echo "Affichage des regles du pare-feu:"
ufw status

#### Enable forwarding for IPV4
vim -O /etc/sysctl.conf INFO/SYSCTL
echo "Rechargement des parametres du kernel..."
sysctl --system
