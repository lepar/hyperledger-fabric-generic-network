#!/bin/bash
KONG_VERSION=1.3
KONG_POSTGRES_PASSWORD="kong"
HOST_IP_ADDRESS=$1

docker rm -f kong kong-database

docker network create kong-net

docker run -d --name kong-database \
--network=kong-net \
-p 5555:5432 \
-e "POSTGRES_USER=kong" \
-e "POSTGRES_DB=kong" \
-e "POSTGRES_PASSWORD=$KONG_POSTGRES_PASSWORD" \
postgres:12.2

sleep 3

docker run --rm \
--network=kong-net \
-e "KONG_DATABASE=postgres" \
-e "KONG_PG_HOST=kong-database" \
-e "KONG_PG_PASSWORD=kong" \
kong:1.3 kong migrations bootstrap

sleep 3

docker run -d --name kong \
--network=kong-net \
--link kong-database:kong-database \
-e "KONG_DATABASE=postgres" \
-e "KONG_PG_HOST=kong-database" \
-e "KONG_PG_PASSWORD=kong" \
-e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
-e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
-e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
-e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
-e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" \
-p 8000:8000 \
-p 8443:8443 \
-p 8001:8001 \
-p 8444:8444 \
kong:$KONG_VERSION

sleep 2

# JWT bearer token for user admin 
# eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwia2V5IjoiYWRtaW4iLCJpYXQiOjE1MTYyMzkwMjIsImlzcyI6ImFkbWluIiwiZXhwIjoxNTE2MjM5MDIyNX0.CuzAZW9ryYNEWXsvHjka9wmAh6dVfWNwi1sYHwJF4JU

# Create usernames
curl -i -X POST \
  --url http://localhost:8001/consumers \
  --data 'username=admin'

#Create users
curl -X POST http://localhost:8001/consumers/admin/jwt \
  --data 'key=admin' --data 'secret=admin'

# define service enrollAdmin
curl -i -X POST -H "Content-Type: application/json" \
  --url http://localhost:8001/services \
  --data '{"name":"enrollAdmin","protocol":"http","host":"'"$HOST_IP_ADDRESS"'","port":3000,"path":"/enrollAdmin"}'

sleep 1

# define routes
curl -i -X POST -H "Content-Type: application/json" \
  --url http://localhost:8001/services/enrollAdmin/routes \
  --data '{"paths":["/enrollAdmin"],"service":{"name":"enrollAdmin"},"preserve_host":false,"strip_path":true}'

sleep 1

# add jwt plugin to service enrollAdmin
curl -o /dev/null -sS -X POST http://localhost:8001/services/enrollAdmin/plugins \
  --data "name=jwt" \
  --data "config.claims_to_verify=exp"

sleep 1

# define service registerUser
curl -i -X POST -H "Content-Type: application/json" \
  --url http://localhost:8001/services \
  --data '{"name":"registerUser","protocol":"http","host":"'"$HOST_IP_ADDRESS"'","port":3000,"path":"/registerUser"}'

sleep 1

# define routes
curl -i -X POST -H "Content-Type: application/json" \
  --url http://localhost:8001/services/registerUser/routes \
  --data '{"paths":["/registerUser"],"service":{"name":"registerUser"},"preserve_host":false,"strip_path":true}'

sleep 1

# add jwt plugin to service registerUser
curl -o /dev/null -sS -X POST http://localhost:8001/services/registerUser/plugins \
  --data "name=jwt" \
  --data "config.claims_to_verify=exp"

# define service invoke
curl -i -X POST -H "Content-Type: application/json" \
  --url http://localhost:8001/services \
  --data '{"name":"invoke","protocol":"http","host":"'"$HOST_IP_ADDRESS"'","port":3000,"path":"/invoke"}'

sleep 1

# define routes
curl -i -X POST -H "Content-Type: application/json" \
  --url http://localhost:8001/services/invoke/routes \
  --data '{"paths":["/invoke"],"service":{"name":"invoke"},"preserve_host":false,"strip_path":true}'

sleep 1

# add jwt plugin to service invoke
curl -o /dev/null -sS -X POST http://localhost:8001/services/invoke/plugins \
  --data "name=jwt" \
  --data "config.claims_to_verify=exp"

sleep 1

# define service query
curl -i -X POST -H "Content-Type: application/json" \
  --url http://localhost:8001/services \
  --data '{"name":"query","protocol":"http","host":"'"$HOST_IP_ADDRESS"'","port":3000,"path":"/query"}'

sleep 1

# define routes
curl -i -X POST -H "Content-Type: application/json" \
  --url http://localhost:8001/services/query/routes \
  --data '{"paths":["/query"],"service":{"name":"query"},"preserve_host":false,"strip_path":true}'

sleep 1

# add jwt plugin to service query
curl -o /dev/null -sS -X POST http://localhost:8001/services/query/plugins \
  --data "name=jwt" \
  --data "config.claims_to_verify=exp"


