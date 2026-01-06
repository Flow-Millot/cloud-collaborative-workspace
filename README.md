# cloud-collaborative-workspace

```
docker compose exec -u www-data app php occ config:system:set trusted_domains 2 --value=app
```

Pour mon asso:

docker compose exec -it keycloak bash
/opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8082 --realm master --user admin --password admin
/opt/keycloak/bin/kcadm.sh update realms/MonAsso -s sslRequired=NONE

Pour mon root:
docker compose exec -it keycloak bash
/opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8082 --realm master --user admin --password admin
/opt/keycloak/bin/kcadm.sh update realms/master -s sslRequired=NONE