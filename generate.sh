# SPDX-License-Identifier: Apache-2.0
export PATH=$GOPATH/src/github.com/hyperledger/fabric/build/bin:${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
CHANNEL_NAME=$1
ORGANIZATION_NAME=$2

# Create config and crypto-config if not exists
mkdir -p config/

# remove previous crypto material and config transactions
rm -fr config/*

# generate channel configuration transaction
configtxgen -profile Channel -outputBlock ./config/channel.tx -channelID $CHANNEL_NAME
if [ "$?" -ne 0 ]; then
  echo "Failed to generate channel configuration transaction..."
  exit 1
fi

# generate anchor peer transaction
configtxgen -profile Channel -outputAnchorPeersUpdate ./config/${ORGANIZATION_NAME}MSPanchors.tx -channelID $CHANNEL_NAME -asOrg ${ORGANIZATION_NAME}MSP
if [ "$?" -ne 0 ]; then
  echo "Failed to generate anchor peer update for MSP..."
  exit 1
fi