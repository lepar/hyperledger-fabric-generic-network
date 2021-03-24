# SPDX-License-Identifier: Apache-2.0

# Arguments
CA_ADDRESS_PORT=$1
COMPANY_DOMAIN=$2
ORDERER_IP_ADDRESS=$3
CA_ADMIN_USER=$4
CA_ADMIN_PASSWORD=$5
ORDERER_PASSWORD=$6

# Orderer directory to save 
ORDERER_DIRECTORY=/etc/hyperledger/fabric-ca-client/crypto-config/ordererOrganizations

# Enroll CA Admin
fabric-ca-client enroll -d -u https://$CA_ADMIN_USER:$CA_ADMIN_PASSWORD@$CA_ADDRESS_PORT

# Rename Key file to key.pem
mv /etc/hyperledger/fabric-ca-server/msp/keystore/*_sk /etc/hyperledger/fabric-ca-server/msp/keystore/key.pem

# Register orderer identities with the CA
fabric-ca-client register -d --id.name orderer.$COMPANY_DOMAIN --id.secret $ORDERER_PASSWORD --id.type orderer -u https://$CA_ADDRESS_PORT

fabric-ca-client register -d --id.name Admin@orderer.$COMPANY_DOMAIN --id.secret $ORDERER_PASSWORD --id.type admin --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert" -u https://$CA_ADDRESS_PORT

# Enroll orderer identity
fabric-ca-client enroll -d -u https://orderer.$COMPANY_DOMAIN:$ORDERER_PASSWORD@$CA_ADDRESS_PORT --csr.hosts orderer.$COMPANY_DOMAIN -M $ORDERER_DIRECTORY/orderers/orderer.$COMPANY_DOMAIN/msp

# Enroll TLS orderer identity
fabric-ca-client enroll -d -u https://orderer.$COMPANY_DOMAIN:$ORDERER_PASSWORD@$CA_ADDRESS_PORT --enrollment.profile tls --csr.hosts orderer.$COMPANY_DOMAIN,$ORDERER_IP_ADDRESS -M $ORDERER_DIRECTORY/orderers/orderer.$COMPANY_DOMAIN/tls

# Enroll orderer Admin identity
fabric-ca-client enroll -d -u https://Admin@orderer.$COMPANY_DOMAIN:$ORDERER_PASSWORD@$CA_ADDRESS_PORT -M $ORDERER_DIRECTORY/users/Admin@orderer.$COMPANY_DOMAIN/msp

# Get TLS for Admin identity
fabric-ca-client enroll -d -u https://Admin@orderer.$COMPANY_DOMAIN:$ORDERER_PASSWORD@$CA_ADDRESS_PORT --enrollment.profile tls --csr.hosts orderer.$COMPANY_DOMAIN,$ORDERER_IP_ADDRESS -M $ORDERER_DIRECTORY/users/Admin@orderer.$COMPANY_DOMAIN/tls

# Get Orderer Admin certs
fabric-ca-client certificate list --id Admin@orderer.$COMPANY_DOMAIN --store $ORDERER_DIRECTORY/users/Admin@orderer.$COMPANY_DOMAIN/msp/admincerts

# Copy Admin certs to Orderers MSP
mkdir $ORDERER_DIRECTORY/msp
cp -r $ORDERER_DIRECTORY/users/Admin@orderer.$COMPANY_DOMAIN/msp/admincerts/ $ORDERER_DIRECTORY/orderers/orderer.$COMPANY_DOMAIN/msp/admincerts

# Get MSP Files for Orderer
# cacerts --orderer
fabric-ca-client getcacert -u https://$CA_ADDRESS_PORT -M $ORDERER_DIRECTORY/msp

# AdminCerts --orderer
fabric-ca-client certificate list --id Admin@orderer.$COMPANY_DOMAIN --store $ORDERER_DIRECTORY/msp/admincerts

# tlscacerts --orderer
fabric-ca-client getcacert -u https://$CA_ADDRESS_PORT -M $ORDERER_DIRECTORY/msp --csr.hosts orderer.$COMPANY_DOMAIN,$ORDERER_IP_ADDRESS --enrollment.profile tls 
