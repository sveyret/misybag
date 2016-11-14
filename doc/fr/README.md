# MisybaG, un mini-système basé sur Gentoo

MisybaG est un système utilisant le gestionnaire de paquet de Gentoo (*Portage*) depuis une machine distante. L'intérêt de déporter le gestionnaire de paquet est de pouvoir s'abstenir de mettre la chaine de compilation et les différents outils de gestion des paquets sur le système, et ainsi créer un système très léger. Notez que le système ainsi créé **n'est pas un Gentoo**.

![Principe de MisybaG](../principle.png "Principe")

Afin de le conserver très léger, très peu de paquets font partie du système (il n'y a initialement presque que *busybox* et *openssh*).

# Langue

Le français étant ma langue maternelle, fournir les documents et messages en français n'est pas une option. Les autres traductions sont bienvenues.

Cependant, l'anglais étant la langue de la programmation, le code, y compris les noms de variable et commentaires, sont en anglais.

# Licence

Copyright © 2016 Stéphane Veyret stephane_POINT_veyret_CHEZ_neptura_POINT_org

MisybaG est un outil libre ; vous pouvez le redistribuer ou le modifier suivant les termes de la GNU General Public License telle que publiée par la Free Software Foundation ; soit la version 3 de la licence, soit (à votre gré) toute version ultérieure.

MisybaG est distribué dans l'espoir qu'il sera utile, mais SANS AUCUNE GARANTIE ; pas même la garantie implicite de COMMERCIALISABILITÉ ni d'ADÉQUATION à UN OBJECTIF PARTICULIER. Consultez la GNU General Public License pour plus de détails.

Vous devez avoir reçu une copie de la GNU General Public License en même temps que MisybaG ; si ce n'est pas le cas, consultez http://www.gnu.org/licenses.

# Installation

La compilation et l'installation sont effectuées simplement par :

    make && make install

Notez que `make install` supporte également la variable `DESTDIR` pour installer ailleurs qu'au niveau de la racine du système.

# Mode d'emploi

## Docker

MisybaG « vampirise » la chaine de compilation. Comme ça l'est fortement conseillé, *SYSROOT* pointe sur /usr/*CTARGET*. Mais il est également encouragé de fusionner *SYSROOT* avec *ROOT*. C'est pour cette raison que le contenu de *SYSROOT* sera déplacé sur *ROOT*, puis un lien symbolique sera créé de *SYSROOT* vers *ROOT*. La chaine de compilation ne sera donc pas utilisable pour un autre système.

Pour cette raison, il est conseillé d'utiliser des conteneurs, tel que *Docker*, pour piloter le système MisybaG. De cette manière, il est possible de créer un conteneur particulier pour chaque système à contrôler.

## Préparation

La première phase est la phase de préparation. Elle est commence par la création du nouveau projet avec la commande :

    misybag new profil répertoire

où *profil* représente un profil spécifique de MisybaG, c'est-à-dire un sous-répertoire de /etc/MisybaG/profiles/MisybaG, et *répertoire* représente le répertoire dans lequel le projet sera créé. Ce dernier argument est optionnel. S'il n'est pas précisé, la création se fera dans le répertoire courant. Si le répertoire spécifié n'existe pas, il est créé.

Cette commande va générer toute une structure dans le répertoire du projet :

* Le répertoire *distroot* est celui qui contiendra la racine complète du système MisybaG. C'est à cet endroit que l'on montera le disque du système MisybaG. En général, dans un premier temps, on montera une carte mémoire, une clé USB ou un disque externe pour y installer le système. Une fois le système installé, on pourra monter à distance la racine du système par SSHFS.
* Le fichier *_env* contient les variables d'environnement essentielles pour le fonctionnement à distance. Il est possible de sourcer ce fichier pour travailler directement sur le système distant.
* Le répertoire *_custom* contient des scripts utilisés à des moments clés qu'il est possible de personnaliser pour compléter l'installation du système.
* Le répertoire *_config* contient des éléments de configuration divers qui peuvent être utilisés par vos scripts personnalisés. Ce répertoire peut également contenir votre clé publique sous le nom *id_rsa.pub*. Si c'est le cas, cette clé sera convenablement positionnée sur le système cible afin de permettre la connexion par SSH sans besoin d'authentification par mot de passe.
* Le répertoire *_portage* contient la configuration de *Portage*. Il peut être personnalisé en fonction des besoins.
* Le répertoire *_layout* contient une structure de répertoires et fichiers qui seront directement copiés sur la cible.

Après avoir exécuté la commande, il n'y a donc plus qu'à compléter cet environnement pour répondre aux besoins de l'utilisateur.

Une fois la préparation terminée, il faudra, pour passer à la suite, que le système de fichier distant soit monté sur *distroot*.

## Installation

L'installation du système MisybaG se fait par la commande :

    misybag sys-install

Cette commande ne devrait être exécutée qu'une seule fois. C'est en effet elle qui va modifier le répertoire *SYSROOT* sur le système Gentoo. La fin de cette commande se termine par l'exécution automatique de la mise à jour.

## Mise à jour

Pour mettre à jour le système distant, il faut utiliser la commande :

    misybag update

Cette commande se contente de mettre à jour les fichiers distants avec le contenu du répertoire *_layout* et d'exécuter les scripts personnalisés.
