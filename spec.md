### **Project Specification: Secure Collaborative Workspace Deployment**

**Role:** DevOps Engineer
**Objective:** Generate a production-ready `docker-compose.yml` and configuration scripts for a collaborative workspace stack.
**Stack:** Nextcloud Hub, OnlyOffice Docs, Keycloak (IdP), Traefik (Proxy), Redis, MariaDB, PostgreSQL.

---

### **1. Infrastructure Constraints**

* **Orchestration:** Docker Compose.
* **Networking:**
* `proxy-net`: Public-facing network for Traefik, Nextcloud, Keycloak, and OnlyOffice web services.
* `backend-net`: Isolated internal network for Databases (MariaDB, Postgres) and Cache (Redis).


* **Security:**
* All external access must be routed through Traefik via HTTPS (TLS).
* Services must not expose ports to the host machine except for Traefik (80/443).
* Secrets (DB passwords, JWT tokens) must be loaded from a `.env` file.



### **2. Service Specifications**

#### **A. Reverse Proxy (Traefik)**

* **Image:** `traefik:v3.0`
* **Configuration:**
* Enable Docker provider to discover services via labels.
* Define EntryPoints: `web` (port 80) and `websecure` (port 443).
* Include a global HTTP-to-HTTPS redirect scheme.
* Mount `/var/run/docker.sock` (read-only).



#### **B. Identity Provider (Keycloak)**

* **Image:** `quay.io/keycloak/keycloak:24.0` (or latest Quarkus-based version).
* **Command:** Start in production mode (`start`) or dev mode (`start-dev`) based on an environment flag.
* **Database:** Connect to a dedicated **PostgreSQL 16** container on `backend-net`.


* **Import:** Configure the container to import a realm configuration (`/opt/keycloak/data/import/realm-export.json`) on startup using the `--import-realm` flag.


* **Env Vars:**
* `KC_DB`, `KC_DB_URL`, `KC_DB_USERNAME`, `KC_DB_PASSWORD`.
* `KC_HOSTNAME`: Must match the public domain (e.g., `auth.association.org`) to avoid redirect loops.





#### **C. Content Collaboration (Nextcloud)**

* **Image:** `nextcloud:29-apache`
* **Database:** Connect to a dedicated **MariaDB 10.11** container on `backend-net`.
* **Cache:** Connect to a dedicated **Redis 7** container on `backend-net` for distributed locking and session caching.
* **Environment Variables:**
* `OVERWRITEHOST`: Set to the public domain (e.g., `cloud.association.org`).


* `OVERWRITEPROTOCOL`: Set to `https` to prevent mixed content warnings behind the proxy.


* `TRUSTED_PROXIES`: CIDR of the Docker network gateway.


* **Volumes:** Persist user data (`/var/www/html`) to a Docker volume.

#### **D. Office Suite (OnlyOffice Docs)**

* **Image:** `onlyoffice/documentserver:latest`
* **Security:**
* Enable JWT token validation (`JWT_ENABLED=true`).
* Set `JWT_SECRET` via environment variable.
* Ensure the JWT secret matches the one configured in Nextcloud.




* **Networking:**
* Must be accessible by Nextcloud via the internal Docker network for server-to-server communication (avoiding hair-pin NAT issues).





---

### **3. Configuration File Requirements**

#### **File Structure**

Create a file tree that looks like this:
/association-workspace
├── docker-compose.yml
├──.env                  # Secrets and domain definitions
├── /proxy
│   └── traefik.yml       # Static config (optional if using CLI args)
├── /keycloak
│   └── realm-export.json # Pre-configured realm with Nextcloud client
└── /nextcloud
└── custom.ini        # PHP overrides (memory limit, upload size)

#### **Environment Variables (`.env`)**

Define the following variables:

* `DOMAIN_NC` (Nextcloud domain)
* `DOMAIN_AUTH` (Keycloak domain)
* `DOMAIN_OFFICE` (OnlyOffice domain)
* `MYSQL_PASSWORD`, `MYSQL_USER`, `MYSQL_DATABASE`
* `POSTGRES_PASSWORD`, `POSTGRES_USER`, `POSTGRES_DB`
* `KEYCLOAK_ADMIN`, `KEYCLOAK_ADMIN_PASSWORD`
* `ONLYOFFICE_JWT_SECRET`

### **4. Post-Deployment Automation Steps**

Generate a script (e.g., `init-config.sh`) that uses `docker exec` to perform the following initialization tasks after the containers are up:

1. **Nextcloud OIDC Setup:**
* Install the `user_oidc` app via `occ app:install user_oidc`.
* Configure the OIDC provider using `occ config:app:set user_oidc...` with the Keycloak client ID, secret, and discovery endpoint.




2. **Nextcloud OnlyOffice Setup:**
* Install the `onlyoffice` app.
* Configure the document server URL and JWT secret using `occ config:app:set onlyoffice...`.
* *Crucial:* Set the internal server URL for server-to-server API requests (e.g., `http://onlyoffice`) to bypass public DNS resolution issues within the cluster.