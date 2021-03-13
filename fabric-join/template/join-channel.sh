CHANNEL_NAME=$1

docker exec cli peer channel fetch 0 channel.block -c $CHANNEL_NAME --orderer orderer.ORGANIZATION_DOMAIN:7050 --tls --cafile /etc/hyperledger/crypto-config/ordererOrganizations/orderers/orderer.ORGANIZATION_DOMAIN/tls/ca.crt

docker exec cli peer channel join -b ./channel.block

# Approve chaincode (manual step, must add all organizations to signature policy and sequence number)
# docker exec cli peer lifecycle chaincode approveformyorg -o orderer.ORGANIZATION_DOMAIN:7050 --channelID CHANNEL_NAME --name chaincode --version 1.0 --sequence 0 --signature-policy "OR('SMTIMSP.member', 'GabineteMSP.member', 'FinancasMSP.member')" --tls --cafile /etc/hyperledger/crypto-config/ordererOrganizations/orderers/orderer.ORGANIZATION_DOMAIN/tls/ca.crt --package-id ccv1:089988a6f40a62d3fc57577660b74dea3e77a5930331a192422ab005f65b1de8