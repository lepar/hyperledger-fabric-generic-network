ORG_NAME=$1
ORG_IP=$2

tar xzvf $ORG_NAME.tar.gz

cp identityFiles/* config/

docker exec cli apk add --update coreutils

docker exec cli `cd artifacts && ./add-remove-org.sh add ${ORG_NAME} ${ORG_IP} ORG_ADMIN_DOMAIN CHANNEL_NAME ORG_ADMIN`

docker exec cli `cd artifacts && peer channel fetch config genesis.block -o orderer1.ORG_ADMIN_DOMAIN:7050 -c system-channel --tls --cafile /etc/hyperledger/crypto-config/ordererOrganizations/orderers/orderer1.ORG_ADMIN_DOMAIN/tls/ca.crt`