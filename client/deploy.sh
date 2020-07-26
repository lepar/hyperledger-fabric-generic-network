#!/bin/bash

# Get the parameters
export NAME_OF_ORGANIZATION=$1
export DOMAIN_OF_ORGANIZATION=$2
export HOST_COMPUTER_IP_ADDRESS=$3
export ORGANIZATION_NAME_LOWERCASE=`echo "$NAME_OF_ORGANIZATION" | tr '[:upper:]' '[:lower:]'`

# Cleanup
sudo rm -rf ./wallet/*

npm install

# Update variables in template
sed -e 's/HOST_COMPUTER_IP_ADDRESS/'$HOST_COMPUTER_IP_ADDRESS'/g' \
    -e 's/DOMAIN_OF_ORGANIZATION/'$DOMAIN_OF_ORGANIZATION'/g' \
    -e 's/NAME_OF_ORGANIZATION/'$NAME_OF_ORGANIZATION'/g' \
    -e 's/ORGANIZATION_NAME_LOWERCASE/'$ORGANIZATION_NAME_LOWERCASE'/g' \
    -e 's/ORGANIZATION_CHANNEL/'${ORGANIZATION_NAME_LOWERCASE}'/g' \
    ./template/connection-org.json > connection-org.json

sed -e 's/HOST_COMPUTER_IP_ADDRESS/'$HOST_COMPUTER_IP_ADDRESS'/g' \
    -e 's/DOMAIN_OF_ORGANIZATION/'$DOMAIN_OF_ORGANIZATION'/g' \
    -e 's/NAME_OF_ORGANIZATION/'$NAME_OF_ORGANIZATION'/g' \
    -e 's/ORGANIZATION_NAME_LOWERCASE/'$ORGANIZATION_NAME_LOWERCASE'/g' \
    ./template/connections.yml > connections.yml

sed -e 's/ORGANIZATION_/'$NAME_OF_ORGANIZATION'/g' \
    -e 's/ORGANIZATION_DOMAIN/'$DOMAIN_OF_ORGANIZATION'/g' \
    ./template/UserManager > ./controllers/UserManager.ts

sed -e 's/ORGANIZATION_NAME/'$NAME_OF_ORGANIZATION'/g' \
    ./template/TransactionManager > ./controllers/TransactionManager.ts

# Get the certificates
cp ../${ORGANIZATION_NAME_LOWERCASE}Ca/tls-cert.pem .
cp ../crypto-config/peerOrganizations/peers/peer.${DOMAIN_OF_ORGANIZATION}/tls/ca.crt ./

npm run build
npm run start