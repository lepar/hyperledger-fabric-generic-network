CHANNEL_NAME=$1
ORG_DOMAIN=$2

docker exec cli peer channel fetch 0 channel.block -c $CHANNEL_NAME --orderer orderer.$ORG_DOMAIN:7050 --tls --cafile /etc/hyperledger/crypto-config/ordererOrganizations/orderers/orderer.$ORG_DOMAIN/tls/ca.crt

docker exec cli peer channel join -b ./channel.block
