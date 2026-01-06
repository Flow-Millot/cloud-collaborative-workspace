# Cloud Collaborative Workspace

Ce projet déploie une suite collaborative complète et sécurisée utilisant Docker. Elle permet le stockage de fichiers (Nextcloud), l'édition de documents en temps réel à plusieurs (OnlyOffice) et une authentification centralisée (Keycloak).

## Architecture des Services

* **Proxy (Nginx)** : Point d'entrée unique (Port 80). Il dirige le trafic vers les bons services et gère les en-têtes HTTP.
* **App (Nextcloud)** : Le cœur du stockage de fichiers.
* **OnlyOffice** : Serveur d'édition de documents (Word, Excel, PPT).
* **Keycloak** : Serveur d'identité (SSO) pour gérer les utilisateurs.
* **DB (MariaDB)** : Base de données pour Nextcloud.
* **Redis** : Cache pour accélérer Nextcloud.

## Prérequis

* Docker et Docker Compose installés sur la machine.
* Nom de domaine configuré : `k2vm-128.mde.epf.fr` (utilisé dans les configs).


## 1. Installation et Démarrage

### Fichiers de configuration

Assurez-vous d'avoir les fichiers suivants à la racine :

1. `docker-compose.yml` : Définit les services, réseaux et volumes.
2. `nginx.conf` : Il contient les correctifs pour les buffers Keycloak et le routage des ressources statiques OnlyOffice.

### Lancement

Démarrez les conteneurs en arrière-plan :

```bash
docker-compose up -d

```

### Correction des Permissions (Indispensable)

OnlyOffice échoue souvent à créer ses dossiers de cache au premier démarrage à cause de droits restreints. Exécutez cette commande une fois les conteneurs lancés pour corriger l'erreur `EACCES` :

```bash
docker exec -u 0 -it onlyoffice bash -c "mkdir -p /var/www/onlyoffice/documentserver/.cache && chown -R ds:ds /var/www/onlyoffice /var/lib/onlyoffice /var/log/onlyoffice"
docker restart onlyoffice

```

## 2. Configuration de Nextcloud (Initialisation)

1. Accédez à `https://k2vm-128.mde.epf.fr/`.
2. Créez votre compte **Admin** (ex: `admin` / `password`).
3. Nextcloud va s'installer (la base de données est configurée automatiquement via les variables d'environnement).

### Autoriser les communications internes

Pour qu'OnlyOffice et Nextcloud puissent se parler via le réseau Docker (noms de conteneurs `app` et `onlyoffice`), vous devez autoriser les domaines internes. Exécutez ces commandes :

```bash
# Autoriser les requêtes vers des serveurs locaux (Docker)
docker exec -u 33 -it app php occ config:system:set allow_local_remote_servers --value=true --type=bool

# Ajouter "app" et "nginx" comme domaines de confiance
docker exec -u 33 -it app php occ config:system:set trusted_domains 2 --value=app
docker exec -u 33 -it app php occ config:system:set trusted_domains 3 --value=nginx

```

## 3. Configuration de Keycloak (SSO)

Keycloak gère les utilisateurs. Nextcloud déléguera l'authentification à Keycloak.

**Accès :** `https://k2vm-128.mde.epf.fr/auth/admin/`
**Login :** `admin` / `admin` (défini dans le docker-compose).

### Étape A : Créer le Royaume (Realm)

1. Cliquez sur le menu déroulant **Master** (haut gauche) > **Create Realm**.
2. Nom : `NextcloudRealm`.
3. Cliquez sur **Create**.

### Étape B : Créer le Client (Le pont vers Nextcloud)

1. Menu **Clients** > **Create client**.
2. **Client ID** : `nextcloud`.
3. **Client authentication** : `On` (Ceci est vital pour avoir un "Secret").
4. Cliquez sur **Save**.
5. Dans l'onglet **Settings** du client :
* **Valid redirect URIs** : `https://k2vm-128.mde.epf.fr/*`
* **Web origins** : `+`
* Cliquez sur **Save**.

6. Dans l'onglet **Credentials** : Copiez le **Client Secret**.

### Étape C : Créer des utilisateurs

1. Menu **Users** > **Add user**.
2. Créez un utilisateur (ex: `etudiant1`). **Email obligatoire** (ex: `etudiant1@epf.fr`) et cochez **Email verified: On**.
3. Onglet **Credentials** > **Set password** (décochez "Temporary").

### Étape D : Activer la création de compte pour les nouveaux utilisateurs

Cela permet d'ajouter un lien "S'inscrire" sur la page de connexion Keycloak. L'utilisateur remplit lui-même son nom, prénom, email et mot de passe. Une fois validé, il est automatiquement créé dans Keycloak et pourra se connecter à Nextcloud (où il sera ajouté au groupe par défaut).

1. Assurez-vous d'être bien sur votre royaume NextcloudRealm (en haut à gauche) et pas sur Master.
2. Dans le menu de gauche, cliquez sur Realm settings.
3. Allez dans l'onglet Login.
4. Activez l'option User registration (Inscription utilisateur) -> ON.

*Conseil : Profitez-en pour activer aussi Forgot password (Mot de passe oublié) -> ON, c'est toujours utile.*

5. Cliquez sur Save (En bas).

## 4. Lier Nextcloud à Keycloak

1. Dans Nextcloud, connectez-vous en Admin.
2. Allez dans **Applications** > Téléchargez et activez **"Social Login"**.
3. Allez dans **Paramètres d'administration** > **Social Login**.
4. Cochez :
* "Prevent creating an account if the email address exists..."
* "Update user profile every login"
* "Do not prune not available user groups" (Optionnel, utile pour les dossiers de groupe).


5. Ajoutez un **"Custom OpenID Connect"** :
* **Internal Name** : `keycloak`
* **Title** : `Connexion via Keycloak`
* **Authorize URL** : `https://k2vm-128.mde.epf.fr/auth/realms/NextcloudRealm/protocol/openid-connect/auth`
* **Token URL** : `https://k2vm-128.mde.epf.fr/auth/realms/NextcloudRealm/protocol/openid-connect/token`
* **User info URL** : `https://k2vm-128.mde.epf.fr/auth/realms/NextcloudRealm/protocol/openid-connect/userinfo`
* **Client ID** : `nextcloud`
* **Client Secret** : (Celui copié à l'étape 3B).
* **Scope** : `openid profile email`
* **Default group** : `users` (ou un groupe créé manuellement, voir section 6).


6. Cliquez sur **Enregistrer**.

## 5. Lier Nextcloud à OnlyOffice

1. Dans Nextcloud > **Applications** > Téléchargez et activez **"ONLYOFFICE"**.
2. Allez dans **Paramètres d'administration** > **ONLYOFFICE**.
3. Configurez comme suit :

- Adresse du ONLYOFFICE Docs : `https://k2vm-128.mde.epf.fr/`
- Clé secrète : `mon_super_secret_jwt`défini dans le docker compose
- Adresse du ONLYOFFICE Docs pour les demandes internes du serveur : `http://onlyoffice/`
- Adresse du serveur pour les demandes internes du ONLYOFFICE Docs : `http://app/`
- Cliquer sur **Enregistrer**

En dessous, cochez les types de fichiers voulus et enregistrer.

## 6. Activer la Collaboration (Dossiers Communs)

Par défaut, les utilisateurs ont des fichiers privés. Pour travailler ensemble :

1. Dans Nextcloud > **Applications** > Installez **"Group folders"**.
2. Allez dans **Paramètres d'administration** > **Dossiers de groupe**.
3. Créez un dossier (ex: "Projet Commun").
4. Ajoutez le groupe `users` (ou celui défini dans Social Login) et `admin`.
5. Donnez les droits **Écriture** et **Partage** et **Supression** si nécessaire.
6. Mettez un quota global pour le dossier partagé.
7. *Astuce* : Dans la config Social Login, assignez le "Default group" à ce groupe pour que tout nouvel utilisateur Keycloak y ait accès automatiquement.

## 7. Ajouter un quota par utilisateur

Pour éviter de surcharger le serveur et atteindre la limite de stockage.

1. Cliquez sur votre avatar (en haut à droite).
2. Cliquez sur Utilisateurs (dans le menu).
3. Regardez tout en bas de la colonne de gauche (sous la liste des groupes "Admins", "Users", etc.). Vous verrez un petit bouton Paramètres (une roue dentée ⚙️). Cliquez dessus.
4. C'est ici que vous trouverez le champ Quota par défaut.
5. Entrez la valeur souhaitée (ex: 5 GB) et cela s'appliquera automatiquement à tous les nouveaux utilisateurs créés.

## Dépannage Courant

* **Erreur 502 Bad Gateway sur Keycloak** :
* *Cause* : Les en-têtes HTTP de Keycloak sont trop gros pour Nginx par défaut.
* *Solution* : Le fichier `nginx.conf` fourni contient déjà `proxy_buffer_size 128k;` et `large_client_header_buffers` pour régler ça.


* **Erreur 404 ou "Page blanche" sur OnlyOffice** :
* *Cause* : Nginx ne redirigeait pas les fichiers statiques (JS, CSS, Polices) vers OnlyOffice.
* *Solution* : La Regex dans `nginx.conf` a été mise à jour pour inclure `sdkjs`, `fonts`, `plugins`, `themes`, etc..


* **Erreur "User exists" dans les logs Keycloak** :
* *Solution* : Ignorez. C'est juste le script de démarrage qui essaie de recréer l'admin à chaque lancement.