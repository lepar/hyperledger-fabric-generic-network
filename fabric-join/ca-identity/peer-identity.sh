# SPDX-License-Identifier: Apache-2.0

CA_ADDRESS_PORT=$1
COMPANY_DOMAIN=$2
IP_ADDRESS=$3
PEER_PASSWORD=$4

# Peer directory to save the peers cryptographic materials
PEER_DIRECTORY=/etc/hyperledger/fabric-ca-client/crypto-config/peerOrganizations

# Register peer, admin and user identities with the CA
fabric-ca-client register -d --id.name peer.$COMPANY_DOMAIN --id.secret $PEER_PASSWORD --id.type peer -u https://$CA_ADDRESS_PORT
fabric-ca-client register -d --id.name Admin@peer.$COMPANY_DOMAIN --id.secret $PEER_PASSWORD --id.type admin --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert" -u https://$CA_ADDRESS_PORT
fabric-ca-client register -d --id.name User@peer.$COMPANY_DOMAIN --id.secret $PEER_PASSWORD --id.type user -u https://$CA_ADDRESS_PORT

# Enroll peer idenities to get certificates
fabric-ca-client enroll -d -u https://peer.$COMPANY_DOMAIN:$PEER_PASSWORD@$CA_ADDRESS_PORT --csr.hosts peer.$COMPANY_DOMAIN -M $PEER_DIRECTORY/peers/peer.$COMPANY_DOMAIN/msp

# Enroll peer identity to get TLS certificates
fabric-ca-client enroll -d -u https://peer.$COMPANY_DOMAIN:$PEER_PASSWORD@$CA_ADDRESS_PORT --csr.hosts peer.$COMPANY_DOMAIN,$IP_ADDRESS --enrollment.profile tls -M $PEER_DIRECTORY/peers/peer.$COMPANY_DOMAIN/tls

# Enroll Admin identities for the Peer MSP
fabric-ca-client enroll -d -u https://Admin@peer.$COMPANY_DOMAIN:$PEER_PASSWORD@$CA_ADDRESS_PORT -M $PEER_DIRECTORY/users/Admin@peer.$COMPANY_DOMAIN/msp

# Get Admin certs
fabric-ca-client certificate list --id Admin@peer.$COMPANY_DOMAIN --store $PEER_DIRECTORY/users/Admin@peer.$COMPANY_DOMAIN/msp/admincerts

# Enroll User identity to the peer
fabric-ca-client enroll -d -u https://User@peer.$COMPANY_DOMAIN:$PEER_PASSWORD@$CA_ADDRESS_PORT -M $PEER_DIRECTORY/users/User@peer.$COMPANY_DOMAIN/msp

# Copy Admin Certs to root of peerOrganization/msp
mkdir $PEER_DIRECTORY/msp
cp -r $PEER_DIRECTORY/users/Admin@peer.$COMPANY_DOMAIN/msp/admincerts $PEER_DIRECTORY/peers/peer.$COMPANY_DOMAIN/msp/admincerts

# Get Admin identity TLS certificates
fabric-ca-client enroll -d -u https://Admin@peer.$COMPANY_DOMAIN:$PEER_PASSWORD@$CA_ADDRESS_PORT --csr.hosts peer.$COMPANY_DOMAIN,$IP_ADDRESS --enrollment.profile tls -M $PEER_DIRECTORY/users/Admin@peer.$COMPANY_DOMAIN/tls

# Get MSP Files for Peer
# cacerts --peer org
fabric-ca-client getcainfo -u https://$CA_ADDRESS_PORT -M $PEER_DIRECTORY/msp

# AdminCerts --peer org
fabric-ca-client certificate list --id Admin@peer.$COMPANY_DOMAIN --store $PEER_DIRECTORY/msp/admincerts

# tlscacerts --peer org
fabric-ca-client getcacert -u https://$CA_ADDRESS_PORT -M $PEER_DIRECTORY/msp --csr.hosts peer.$COMPANY_DOMAIN,$IP_ADDRESS --enrollment.profile tls