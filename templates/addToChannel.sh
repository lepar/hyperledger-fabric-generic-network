ORG_NAME=$1
ORG_IP=$2

tar xzvf $ORG_NAME.tar.gz

cp identityFiles/* config/

docker exec cli apk add --update coreutils

docker exec cli /bin/sh -c "cd artifacts && /etc/hyperledger/artifacts/add-remove-org.sh add ${ORG_NAME} ${ORG_IP} ORG_ADMIN_DOMAIN CHANNEL_NAME ORG_ADMIN_NAME"

docker exec -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/crypto-config/ordererOrganizations/users/Admin@orderer1.ORG_ADMIN_DOMAIN/msp" -e "CORE_PEER_ADDRESS=orderer1.ORG_ADMIN_DOMAIN:7050" -e "CORE_PEER_LOCALMSPID=ORG_ADMIN_NAMEOrdererMSP" -e "CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/crypto-config/ordererOrganizations/orderers/orderer1.ORG_ADMIN_DOMAIN/tls/ca.crt" cli peer channel fetch config /etc/hyperledger/artifacts/genesis.block -o orderer1.ORG_ADMIN_DOMAIN:7050 -c system-channel --tls --cafile /etc/hyperledger/crypto-config/ordererOrganizations/orderers/orderer1.ORG_ADMIN_DOMAIN/tls/ca.crt