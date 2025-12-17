# Cloud Collaborative Workspace

A production-ready, locally deployable collaborative workspace stack featuring **Nextcloud**, **Keycloak** (SSO), and **OnlyOffice**, orchestrated with **Docker Compose** and **Traefik**.

## 🚀 Quick Start

### Prerequisites
*   **Docker Desktop** (Windows/Mac) or **Docker Engine** (Linux)
*   **Git**
*   *(Windows Users)* **WSL2** or **Git Bash** is recommended for running the init script.

### Installation

1.  **Clone the repository**
    ```bash
    git clone <repository-url>
    cd cloud-collaborative-workspace
    ```

2.  **Start the Stack**
    ```bash
    docker compose up -d
    ```

3.  **Wait for Initialization**
    Nextcloud needs 1-2 minutes to perform its first-time installation. You can check progress with:
    ```bash
    docker compose logs -f nextcloud
    ```
    Wait until you see "Nextcloud was successfully installed".

4.  **Configure Integrations**
    Run the initialization script to set up Single Sign-On (SSO) and OnlyOffice integration:
    ```bash
    bash init-config.sh
    ```

## 🌐 Accessing Services

The stack uses `*.localhost` domains which automatically resolve to your local machine.

| Service | URL | Default Credentials |
| :--- | :--- | :--- |
| **Nextcloud** | [https://cloud.localhost](https://cloud.localhost) | `admin` / `admin_password` |
| **Keycloak** | [https://auth.localhost](https://auth.localhost) | `admin` / `admin_password` |
| **OnlyOffice** | [https://office.localhost](https://office.localhost) | *(Backend Service)* |

> **⚠️ Security Warning:** Since this runs locally with self-signed certificates, your browser will warn you that the connection is not secure. You must click **"Advanced" -> "Proceed to..."** for **ALL** domains to ensure they can communicate with each other.

## 🏗️ Architecture

*   **Traefik**: Reverse proxy handling SSL termination and routing.
*   **Nextcloud**: Main file storage and collaboration platform.
*   **Keycloak**: Identity Provider (IdP) managing users and SSO via OIDC.
*   **OnlyOffice**: Document editing server (Word, Excel, PowerPoint).
*   **Databases**: MariaDB (Nextcloud), PostgreSQL (Keycloak), Redis (Caching).

## 🛠️ Troubleshooting

*   **"Command not found" in init script**: Ensure you are running `bash init-config.sh`. On Windows, use Git Bash or WSL.
*   **Browser Redirect Loops**: Ensure you have accepted the SSL warning for `auth.localhost` by visiting it directly.
*   **Docker Errors**: If you see "pipe/dockerDesktopLinuxEngine" errors on Windows, ensure Docker Desktop is running.