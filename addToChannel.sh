ORG_NAME=$1
ORG_IP=$2

tar xzvf $ORG_NAME.tar.gz

cp identityFiles/* config/

docker exec cli apk add --update coreutils

docker exec cli `cd artifacts && ./add-remove-org.sh add ${ORG_NAME} ${ORG_IP} Test_DOMAIN testchannel} Test`

docker exec cli `cd artifacts && peer channel fetch config genesis.block -o orderer1.Test_DOMAIN:7050 -c system-channel --tls --cafile /etc/hyperledger/crypto-config/ordererOrganizations/orderers/orderer1.Test_DOMAIN/tls/ca.crt`