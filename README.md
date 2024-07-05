# Projet VPN

## Environment
```
VirtualBox
2 Machines Virtuelle - Debian 12.5 x64 (with systemd)
    - CA
    - VPN
Systeme Hote - Windows 10 Pro x64

easy-rsa compile a partir de la derniere version.
packages:
    - openvpn (v2.6).
    - ufw.
```

### Description
Pour ce rapprocher le plus possible d'une infrastructure professionnelle, j'ai volontairement separe l'authorite de certification et le serveur vpn. Ils communiquent donc par le reseau virtuel propre a VirtualBox.

La machine virtuelle VPN est bridgee sur mon reseau local, avec une DMZ qui pointe sur la machine virtuelle (afin de simplifier l'ouverture des ports sur ma box)

Ce choix ma contraint a ne pas faire la partie 3 du projet, qui constite a mettre en place une 2FA. Je suppose qu'il est preferable a ce moment precis, d'automatiser la creation des utilisateurs, avec un certificat et une cle propre a chacuns. (et donc un TOTP qui est propre a chaque utilisateurs)
J'ai egalement a ma disposition une Yubikey mais ne souhaite pas travailler sur les certificats deja present sur cette derniere.

## Deroulement du projet
J'ai commencer par l'installation des packages requis.
```bash
sudo apt update
sudo apt install openvpn ufw libpam-google-authenticator libqrencode-dev qrencode

mkdir -p /etc/openvpn/gauth
```

Je pars du postulat que les interfaces reseaux n'ont pas besoin d'etre configures.
Je recupere easy-rsa a partir du depot github: https://github.com/OpenVPN/easy-rsa.git

A ce moment precis, afin de pouvoir compiler easy-rsa correctement j'ai du installer certaines dependances lie au projet.
Sur la machine CA:
```bash
git clone https://github.com/OpenVPN/easy-rsa 
sudo apt install python3-pip
pip3 install markdown
# compilation
easy-rsa/build/build-dist.sh
tar -zxvf dist-staging/EasyRSA-3.2.1.tgz -C ~/.
```
Puis on echangera les cles depuis le CA vers le serveur VPN avec scp (toujours dans ce sens)
```bash
scp fichier_local n0x4z3r@serveur_vpn:<chemin_distant>
```
Il faut donc transferer les certificats et cles du serveur et du CA vers la machine du serveur vpn.

Je configure le serveur vpn ainsi que le pare-feu, pour permettre la redirection de port. (firewall.sh)
Une fois la configuration en place, j'ai juste a utiliser systemd pour activer la configuration serveur en question (ici server)
```bash
systemctl start openvpn@server
```

pour creer un utilisateur on utilisera simplement la commande suivante:
```
sudo useradd -s /bin/false -d /dev/null -g <user> <user>
```

Pour verifier que les parametres et le fonctionnement du serveur est correct, il faut augmenter la verbosite du serveur.
Et verifier les logs, du demarrage du serveur jusqu'a qu'une connexion soit etabli avec un client.

J'ai voulu utilise des cles en courbes elliptiques, car elles sont plus performantes que le chiffrement RSA, je m'eloigne egalement des courbes NIST, mais a defaut je prefere utiliser la secp521r1 car c'est une des seules qui n'est pas concernee par une possible manipulations des constantes primitives. (a noter que X25519 n'est pas une courbe, j'ai configure easy-rsa de facon a utiliser ed25519)

Concernant les suite cryptographiques, j'ai une preference dans cet ordre: chacha20-poly1305, AES-256-GCM.
On prefera egalement ECDHE-ECDSA a un simple DHE. Pour l'echange de cles et l'authentification. (non mis en place du a l'utilisation de ed25519)

Normalement les cles et certificats ne sortents par du CA, mais pour le projet j'ai mis en place le script pour creer le fichier client .ovpn sur la machine du serveur.
Par la suite j'ai recuperer les fichiers .ovpn par FTP afin d'essayer sur un autre ordinateur.

Les fichiers de configuration sont disponible dans le dossier root

Pour la MFA avec google authenticator, on utilisera cette commande pour generer les bons secrets:
```
su -c "google-authenticator -t -d -r3 -R30 -f -W -e5 -l 'VPN ${USER}' -s /etc/openvpn/gauth/${USER}" gauth
```

La commande est inclus dans le scripte de generation du fichier .ovpn, il faudra donc ajouter le prefix sudo, si l'ont souhaite le faire manuellement
