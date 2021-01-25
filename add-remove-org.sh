# Input organization info parameters
OPERATION=$1
ORG_NAME=$2
ORGANIZATION_IP_ADDRESS=$3
ORGANIZATION_DOMAIN=$4
CHANNEL=$5
ORG_ADMIN=$6

ORG_DIRECTORY=/etc/hyperledger/artifacts

function ordererEnvVariables(){
    export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/crypto-config/ordererOrganizations/users/Admin@orderer1.$ORGANIZATION_DOMAIN/msp
    export CORE_PEER_ADDRESS=orderer1.$ORGANIZATION_DOMAIN:7050
    export CORE_PEER_LOCALMSPID=${ORG_ADMIN}OrdererMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/crypto-config/ordererOrganizations/orderers/orderer1.$ORGANIZATION_DOMAIN/tls/ca.crt
}

function peerEnvVariablesForBlock(){
    export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/crypto-config/ordererOrganizations/users/Admin@orderer1.$ORGANIZATION_DOMAIN/msp
    export CORE_PEER_ADDRESS=peer.$ORGANIZATION_DOMAIN:7051
    export CORE_PEER_LOCALMSPID=${ORG_ADMIN}OrdererMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/crypto-config/ordererOrganizations/orderers/orderer1.$ORGANIZATION_DOMAIN/tls/ca.crt
}

function peerEnvVariables(){
    export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/crypto-config/peerOrganizations/users/Admin@peer.$ORGANIZATION_DOMAIN/msp
    export CORE_PEER_ADDRESS=peer.$ORGANIZATION_DOMAIN:7051
    export CORE_PEER_LOCALMSPID=${ORG_ADMIN}MSP
    export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/crypto-config/peerOrganizations/orderers/peer.$ORGANIZATION_DOMAIN/tls/ca.crt

}

function fetchConfigBlock(){
    peer channel fetch config config_block.pb -o orderer1.$ORGANIZATION_DOMAIN:7050 -c $CHANNEL_NAME --tls --cafile /etc/hyperledger/crypto-config/ordererOrganizations/orderers/orderer1.$ORGANIZATION_DOMAIN/tls/ca.crt
    configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json
}

function addOrgChannel(){
    # Add to organization channel group
    jq -s '.[0] * {"channel_group":{"groups":{"Orderer":{"groups": {"'$ORG_NAME'OrdererMSP":.[1]}}}}}' config.json ${ORG_NAME}OrdererMSP.json > modified_config.json

    # Add orderer address to addresses list
    jq ".channel_group.values.OrdererAddresses.value.addresses += [\"$ORGANIZATION_IP_ADDRESS:7050\"]" modified_config.json > modified_config1.json

    if [ $CHANNEL_NAME == "system-channel" ]; then
        # Add new Org MSP to Consortium channel group
        jq -s ".[0] * {\"channel_group\":{\"groups\":{\"Consortiums\":{\"groups\":{\"${ORG_ADMIN}Consortium\":{\"groups\": {\"${ORG_NAME}MSP\":.[1]}}}}}}}" modified_config1.json ${ORG_NAME}MSP.json > modified_config4.json

    else
        echo "ADDING TO APPLICATION CHANNEL"
        jq -s ".[0] * {\"channel_group\":{\"groups\":{\"Application\":{\"groups\":{\"${ORG_NAME}MSP\":.[1]}}}}}" modified_config1.json ${ORG_NAME}MSP.json > modified_config2.json

         # Add to Endorsement policy
        jq '.channel_group.groups.Application.policies.Endorsement.policy.value.identities += [{"principal":{"msp_identifier": "'${ORG_NAME}'MSP","role": "MEMBER"},"principal_classification": "ROLE"}]' modified_config2.json > modified_config3.json

        # Add to LifecycleEndorsement lists
        jq '.channel_group.groups.Application.policies.LifecycleEndorsement.policy.value.identities += [{"principal":{"msp_identifier": "'${ORG_NAME}'MSP","role": "MEMBER"},"principal_classification": "ROLE"}]' modified_config3.json > modified_config4.json

      fi

    # Add to consenters list
    export FLAG=$(if [ "$(uname -s)" == "Linux" ]; then echo "-w 0"; else echo "-b 0"; fi)

    TLS_FILE=server.crt
    echo "{\"client_tls_cert\":\"$(cat $TLS_FILE | base64 $FLAG)\",\"host\":\"$ORGANIZATION_IP_ADDRESS\",\"port\":7050,\"server_tls_cert\":\"$(cat $TLS_FILE | base64 $FLAG)\"}" > $PWD/new-consenter.json

    jq ".channel_group.groups.Orderer.values.ConsensusType.value.metadata.consenters += [$(cat new-consenter.json)]" modified_config4.json > modified_config_final.json

}

function removeOrgSystemChannel(){
    # Delete organization from Consortium and Orderer values
    jq "del(.channel_group.groups.Consortiums.groups.${ORG_ADMIN}Consortium.groups.${ORG_NAME}MSP)" config.json > modified_config.json
    jq "del(.channel_group.groups.Orderer.groups.${ORG_NAME}OrdererMSP)" modified_config.json > modified_config1.json

    # Remove organizations IP Address
    jq '.channel_group.values.OrdererAddresses.value.addresses |= map(select( test('\"$ORGANIZATION_IP_ADDRESS':7050'\"') | not))' modified_config1.json > modified_config2.json   

    # Remove organization from consenters
    jq 'del(.channel_group.groups.Orderer.values.ConsensusType.value.metadata.consenters[] | select(.host == '\"$ORGANIZATION_IP_ADDRESS\"'))' modified_config2.json > modified_config_final.json

}

function removeOrgApplicationChannel(){
    # Delete organization from Application group
    jq "del(.channel_group.groups.Application.groups.${ORG_NAME}MSP)" config.json > modified_config.json

    # Delete organization from Endorsement policy
    jq 'del(.channel_group.groups.Application.policies.Endorsement.policy.value.identities[] | select(.principal.msp_identifier == "'${ORG_NAME}'MSP"))' modified_config.json > modified_config1.json

    # Delete organization from Lifecycle Endorsement
    jq 'del(.channel_group.groups.Application.policies.LifecycleEndorsement.policy.value.identities[] | select(.principal.msp_identifier == "'${ORG_NAME}'MSP"))' modified_config1.json > modified_config2.json

    # Delete organization from Orderer group
    jq "del(.channel_group.groups.Orderer.groups.${ORG_NAME}OrdererMSP)" modified_config2.json > modified_config3.json

    # Remove organizations IP Address
    jq '.channel_group.values.OrdererAddresses.value.addresses |= map(select( test('\"$ORGANIZATION_IP_ADDRESS':7050'\"') | not))' modified_config3.json > modified_config4.json   

    # Remove organization from consenters
    jq 'del(.channel_group.groups.Orderer.values.ConsensusType.value.metadata.consenters[] | select(.host == '\"$ORGANIZATION_IP_ADDRESS\"'))' modified_config4.json > modified_config_final.json


}

function sendUpdate(){

    configtxlator proto_encode --input config.json --type common.Config --output config.pb

    configtxlator proto_encode --input modified_config_final.json --type common.Config --output modified_config.pb

    configtxlator compute_update --channel_id $CHANNEL_NAME --original config.pb --updated modified_config.pb --output org_update.pb

    configtxlator proto_decode --input org_update.pb --type common.ConfigUpdate | jq . > org_update.json

    echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat org_update.json)'}}}' | jq . > org_update_in_envelope.json

    configtxlator proto_encode --input org_update_in_envelope.json --type common.Envelope --output org_update_in_envelope.pb

    peer channel signconfigtx -f org_update_in_envelope.pb

    if [ $CHANNEL_NAME != "system-channel" ]; then
        peerEnvVariables
    fi

    peer channel update -f org_update_in_envelope.pb -c $CHANNEL_NAME -o orderer1.$ORGANIZATION_DOMAIN:7050 --tls --cafile /etc/hyperledger/crypto-config/ordererOrganizations/orderers/orderer1.$ORGANIZATION_DOMAIN/tls/ca.crt

}

if [ $OPERATION == "add" ]; then

    mkdir $ORG_DIRECTORY/org-temp

    cp ${ORG_NAME}OrdererMSP.json ./org-temp
    cp ${ORG_NAME}MSP.json ./org-temp
    cp server.crt ./org-temp

    pushd $ORG_DIRECTORY/org-temp

    # Add to system channel
    export CHANNEL_NAME='system-channel'
    ordererEnvVariables
    fetchConfigBlock
    addOrgChannel
    sendUpdate

    sleep 5

    # Add to application channel
    export CHANNEL_NAME=$CHANNEL
    peerEnvVariablesForBlock
    fetchConfigBlock
    addOrgChannel
    sendUpdate

    popd

elif [ $OPERATION == "remove" ]; then

    mkdir $ORG_DIRECTORY/org-temp
    pushd $ORG_DIRECTORY/org-temp

    # Remove from system channel
    export CHANNEL_NAME='system-channel'
    ordererEnvVariables
    fetchConfigBlock
    removeOrgSystemChannel
    sendUpdate

    sleep 5

    # Remove from application channel
    export CHANNEL_NAME=$CHANNEL
    peerEnvVariablesForBlock
    fetchConfigBlock
    removeOrgApplicationChannel
    sendUpdate

    popd
fi
