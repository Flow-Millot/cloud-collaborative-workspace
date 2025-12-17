#!/bin/bash

# Fix line endings in .env if run on Windows/WSL
sed -i 's/\r$//' .env

# Load environment variables
set -a
source .env
set +a

echo "Waiting for Nextcloud to be ready..."
sleep 30 # Adjust as needed or use a wait-for-it script

echo "Installing user_oidc app..."
docker compose exec --user www-data -T nextcloud php occ app:install user_oidc || true

echo "Configuring OIDC provider..."
# Note: The spec mentions config:app:set, but creating a provider usually requires user_oidc:provider
# We will try to create the provider if it doesn't exist.
docker compose exec --user www-data -T nextcloud php occ user_oidc:provider keycloak \
  --clientid="nextcloud" \
  --clientsecret="change_me_client_secret" \
  --discoveryuri="https://${DOMAIN_AUTH}/realms/association/.well-known/openid-configuration" \
  --scope="openid email profile" || echo "Provider might already exist"

echo "Installing onlyoffice app..."
docker compose exec --user www-data -T nextcloud php occ app:install onlyoffice || true

echo "Configuring OnlyOffice..."
docker compose exec --user www-data -T nextcloud php occ config:app:set onlyoffice DocumentServerUrl --value="https://${DOMAIN_OFFICE}"
docker compose exec --user www-data -T nextcloud php occ config:app:set onlyoffice DocumentServerInternalUrl --value="http://onlyoffice"
docker compose exec --user www-data -T nextcloud php occ config:app:set onlyoffice jwt_secret --value="${ONLYOFFICE_JWT_SECRET}"

echo "Configuration complete!"
