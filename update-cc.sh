VERSION=$1
SEQUENCE=$2

ORGANIZATION_DOMAIN=
CHAINCODE_NAME=
CHANNEL=

pushd chaincode
npm install
npm run build
popd 

# Package chaincode
docker exec cli peer lifecycle chaincode package $CHAINCODE_NAME.tar.gz --path /etc/hyperledger/chaincode --lang node --label ccv1

# Install the chaincode
docker exec cli peer lifecycle chaincode install $CHAINCODE_NAME.tar.gz >&ccVer.txt
sleep 2

# Retrieve chaincode package ID
sed -n '$'p ccVer.txt >&ccId.txt
export PACKAGE_ID=`grep -oP '\b(\w{64})\b' ccId.txt`
echo $PACKAGE_ID

# Approve chaincode for org
docker exec cli peer lifecycle chaincode approveformyorg -o orderer1.$ORGANIZATION_DOMAIN:7050 --ordererTLSHostnameOverride orderer1.$ORGANIZATION_DOMAIN --channelID $CHANNEL --name $CHAINCODE_NAME --version $VERSION --sequence $SEQUENCE --tls --cafile /etc/hyperledger/crypto-config/ordererOrganizations/orderers/orderer1.$ORGANIZATION_DOMAIN/tls/ca.crt --package-id ccv1:${PACKAGE_ID}

# Check commit readiness
docker exec cli peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL --name $CHAINCODE_NAME --version $VERSION --sequence $SEQUENCE --tls true --cafile /etc/hyperledger/crypto-config/ordererOrganizations/orderers/orderer1.$ORGANIZATION_DOMAIN/tls/ca.crt --output json

# Commit the chaincode
docker exec cli peer lifecycle chaincode commit -o orderer1.$ORGANIZATION_DOMAIN:7050 --channelID $CHANNEL --name $CHAINCODE_NAME --version $VERSION --sequence $SEQUENCE --tls true --cafile /etc/hyperledger/crypto-config/ordererOrganizations/orderers/orderer1.$ORGANIZATION_DOMAIN/tls/ca.crt --peerAddresses peer.$ORGANIZATION_DOMAIN:7051 --tlsRootCertFiles /etc/hyperledger/crypto-config/peerOrganizations/peers/peer.$ORGANIZATION_DOMAIN/tls/ca.crt 