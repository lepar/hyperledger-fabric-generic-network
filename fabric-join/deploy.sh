# SPDX-License-Identifier: Apache-2.0
#set -ev
#!/bin/sh

function exportVariables(){

  # Organization information that you wish to build and deploy
  export NAME_OF_ORGANIZATION=$NAME_OF_ORGANIZATION
  export DOMAIN_OF_ORGANIZATION=$DOMAIN_OF_ORGANIZATION
  export HOST_COMPUTER_IP_ADDRESS=$HOST_COMPUTER_IP_ADDRESS
  export ORGANIZATION_NAME_LOWERCASE=`echo "$NAME_OF_ORGANIZATION" | tr '[:upper:]' '[:lower:]'`
  export CA_ADDRESS_PORT=ca.$DOMAIN_OF_ORGANIZATION:7054

  # Security defaults
  # Couch DB credentials
  export COUCH_DB_USERNAME=admin
  export COUCH_DB_PASSWORD=adminpw

  # Certificate authority credentials
  export CA_ADMIN_USER=admin
  export CA_ADMIN_PASSWORD=adminpw

  # Orderer credentials
  ORDERER_PASSWORD=adminpw

  # Peer credentials
  PEER_PASSWORD=peerpw

}

read -p "Organization Name: "  NAME_OF_ORGANIZATION
read -p "Organization Domain: " DOMAIN_OF_ORGANIZATION
read -p "Computer IP Address: " HOST_COMPUTER_IP_ADDRESS

exportVariables

./clean-all.sh

# Substitutes organizations information in the configtx template to match organizations name, domain and ip address
sed -e 's/organization_name/'$NAME_OF_ORGANIZATION'/g' -e 's/organization_domain/'$DOMAIN_OF_ORGANIZATION'/g' -e 's/ip_address/'$HOST_COMPUTER_IP_ADDRESS'/g'  configtx_template.yaml > configtx.yaml

# Start the certficate authority
docker-compose -p fabric-network -f docker-compose.yml up -d ca
sleep 3

docker exec ca.$DOMAIN_OF_ORGANIZATION /bin/bash -c "cd /etc/hyperledger/artifacts/  && ./orderer-identity.sh $CA_ADDRESS_PORT $DOMAIN_OF_ORGANIZATION $HOST_COMPUTER_IP_ADDRESS $CA_ADMIN_USER $CA_ADMIN_PASSWORD $ORDERER_PASSWORD"


# Generate identity and cryptographic materials for the peer 
docker exec ca.$DOMAIN_OF_ORGANIZATION /bin/bash -c "cd /etc/hyperledger/artifacts/  && ./peer-identity.sh $CA_ADDRESS_PORT $DOMAIN_OF_ORGANIZATION $HOST_COMPUTER_IP_ADDRESS $PEER_PASSWORD"

# Move the crypto-config folder to manipulate it more easily away from the dockers users' restrictions
sudo mv ./${ORGANIZATION_NAME_LOWERCASE}Ca/client/crypto-config ./
sudo chmod -R 777 ./crypto-config

# Move TLS certificates for the orderer

ORDERER_DIRECTORY=./crypto-config/ordererOrganizations/orderers
sudo mv $ORDERER_DIRECTORY/orderer.$DOMAIN_OF_ORGANIZATION/tls/signcerts/cert.pem $ORDERER_DIRECTORY/orderer.$DOMAIN_OF_ORGANIZATION/tls/server.crt
sudo mv $ORDERER_DIRECTORY/orderer.$DOMAIN_OF_ORGANIZATION/tls/keystore/*_sk $ORDERER_DIRECTORY/orderer.$DOMAIN_OF_ORGANIZATION/tls/server.key
sudo mv $ORDERER_DIRECTORY/orderer.$DOMAIN_OF_ORGANIZATION/tls/tlscacerts/*.pem $ORDERER_DIRECTORY/orderer.$DOMAIN_OF_ORGANIZATION/tls/ca.crt

# Delete empty directories
sudo rm -rf $ORDERER_DIRECTORY/orderer.$DOMAIN_OF_ORGANIZATION/tls/{cacerts,keystore,signcerts,tlscacerts,user}

# Peers crypto-config directory
PEER_DIRECTORY=./crypto-config/peerOrganizations/peers/peer.$DOMAIN_OF_ORGANIZATION

# Move the Peer TLS files to match cryptogen hierarchy
sudo mv $PEER_DIRECTORY/tls/signcerts/cert.pem $PEER_DIRECTORY/tls/server.crt
sudo mv $PEER_DIRECTORY/tls/keystore/*_sk $PEER_DIRECTORY/tls/server.key
sudo mv $PEER_DIRECTORY/tls/tlscacerts/*.pem $PEER_DIRECTORY/tls/ca.crt

# Delete the peers empty directory
sudo rm -rf $PEER_DIRECTORY/tls/{cacerts,keystore,signcerts,tlscacerts,user}

# Start the network with docker-compose
docker-compose -f docker-compose.yml up -d peer couchdb cli orderer

sleep 30

mkdir identityFiles

# Generate json identities to send to admin org to enter a channel
./configtxgen -printOrg ${NAME_OF_ORGANIZATION}MSP > identityFiles/${NAME_OF_ORGANIZATION}MSP.json
./configtxgen -printOrg ${NAME_OF_ORGANIZATION}OrdererMSP > identityFiles/${NAME_OF_ORGANIZATION}OrdererMSP.json
cp crypto-config/ordererOrganizations/orderers/orderer.${DOMAIN_OF_ORGANIZATION}/tls/server.crt identityFiles/

tar -czvf $NAME_OF_ORGANIZATION.tar.gz identityFiles/

mkdir config
cp chaincode.tar.gz config/

docker exec cli peer lifecycle chaincode install artifacts/chaincode.tar.gz