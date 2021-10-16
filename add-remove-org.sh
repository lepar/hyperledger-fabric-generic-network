OPERATION=$1
NEW_ORG_NAME=$2
ORGANIZATION_IP=$3
ORGANIZATION_DOMAIN=$4
CHANNEL=$5
ORG_ADMIN=$6

ORG_DIRECTORY=/etc/hyperledger/artifacts

TEMP_DIRECTORY=$ORG_DIRECTORY/org-temp

function peerEnvVariables(){
    export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/crypto-config/peerOrganizations/users/Admin@peer1.$ORGANIZATION_DOMAIN/msp
    export CORE_PEER_ADDRESS=peer1.$ORGANIZATION_DOMAIN:7051
    export CORE_PEER_LOCALMSPID=${ORG_ADMIN}MSP
    export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/crypto-config/peerOrganizations/orderers/peer1.$ORGANIZATION_DOMAIN/tls/ca.crt
}

function fetchConfigBlock(){
    peer channel fetch config config_block.pb -o orderer1.$ORGANIZATION_DOMAIN:7050 -c $CHANNEL --tls --cafile /etc/hyperledger/crypto-config/ordererOrganizations/orderers/orderer1.$ORGANIZATION_DOMAIN/tls/ca.crt
    configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > $TEMP_DIRECTORY/config.json
}

function addOrgChannel(){

    echo "ADDING ORG TO CHANNEL"

    jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups":{"'$NEW_ORG_NAME'MSP":.[1]}}}}}' $TEMP_DIRECTORY/config.json ${NEW_ORG_NAME}MSP.json > $TEMP_DIRECTORY/config2.json

    jq '
        .channel_group.groups.Application.policies.Endorsement.policy.value.identities += [{"principal":{"msp_identifier": "'$NEW_ORG_NAME'MSP","role": "MEMBER"},"principal_classification": "ROLE"}] |
        .channel_group.groups.Application.policies.LifecycleEndorsement.policy.value.identities += [{"principal":{"msp_identifier": "'$NEW_ORG_NAME'MSP","role": "MEMBER"},"principal_classification": "ROLE"}]
    ' $TEMP_DIRECTORY/config2.json > $TEMP_DIRECTORY/config3.json

    export FLAG=$(if [ "$(uname -s)" == "Linux" ]; then echo "-w 0"; else echo "-b 0"; fi)

    TLS_FILE=$TEMP_DIRECTORY/server.crt

    echo "{\"client_tls_cert\":\"$(cat $TLS_FILE | base64 $FLAG)\",\"host\":\"$ORGANIZATION_IP\",\"port\":7050,\"server_tls_cert\":\"$(cat $TLS_FILE | base64 $FLAG)\"}" > $TEMP_DIRECTORY/new-consenter.json

    jq -s '.[0] * {"channel_group":{"groups":{"Orderer":{"groups": {"'$NEW_ORG_NAME'OrdererMSP":.[1]}}}}}' $TEMP_DIRECTORY/config3.json ${NEW_ORG_NAME}OrdererMSP.json > $TEMP_DIRECTORY/config4.json

    # Add orderer address to addresses list
    jq "
        .channel_group.values.OrdererAddresses.value.addresses += [\"$ORGANIZATION_IP:7050\"] |
        .channel_group.groups.Orderer.values.ConsensusType.value.metadata.consenters += [$(cat $TEMP_DIRECTORY/new-consenter.json)]
    " $TEMP_DIRECTORY/config4.json > $TEMP_DIRECTORY/modified_config_final.json

}


function removeOrgChannel(){

    # Delete organization from Lifecycle Endorsement
    jq '
        del(.channel_group.groups.Application.groups.'$NEW_ORG_NAME'MSP) |
        del(.channel_group.groups.Application.policies.Endorsement.policy.value.identities[] | select(.principal.msp_identifier == "'$NEW_ORG_NAME'MSP")) |
        del(.channel_group.groups.Application.policies.LifecycleEndorsement.policy.value.identities[] | select(.principal.msp_identifier == "'${NEW_ORG_NAME}'MSP"))
    ' $TEMP_DIRECTORY/config.json > $TEMP_DIRECTORY/config2.json

    # Remove organizations IP Address
    jq '
        del(.channel_group.groups.Orderer.groups.'$NEW_ORG_NAME'OrdererMSP) |
        .channel_group.values.OrdererAddresses.value.addresses |= map(select( test('\"$ORGANIZATION_IP\"') | not)) | 
        del(.channel_group.groups.Orderer.values.ConsensusType.value.metadata.consenters[] | select(.host == '\"$ORGANIZATION_IP\"'))
    ' $TEMP_DIRECTORY/config2.json > $TEMP_DIRECTORY/modified_config_final.json
}

function sendUpdate(){

    configtxlator proto_encode --input config.json --type common.Config --output config.pb

    configtxlator proto_encode --input modified_config_final.json --type common.Config --output modified_config.pb

    configtxlator compute_update --channel_id $CHANNEL --original config.pb --updated modified_config.pb --output org_update.pb

    configtxlator proto_decode --input org_update.pb --type common.ConfigUpdate | jq . > org_update.json

    echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL'", "type":2}},"data":{"config_update":'$(cat org_update.json)'}}}' | jq . > org_update_in_envelope.json

    configtxlator proto_encode --input org_update_in_envelope.json --type common.Envelope --output org_update_in_envelope.pb

    peer channel signconfigtx -f org_update_in_envelope.pb
    
    export CORE_PEER_LOCALMSPID=${ORG_ADMIN}OrdererMSP
    
    peer channel update -f org_update_in_envelope.pb -c $CHANNEL -o orderer1.$ORGANIZATION_DOMAIN:7050 --tls --cafile /etc/hyperledger/crypto-config/ordererOrganizations/orderers/orderer1.$ORGANIZATION_DOMAIN/tls/ca.crt

}

if [ $OPERATION == "add" ]; then
    peerEnvVariables
    mkdir $ORG_DIRECTORY/org-temp

    cp ${NEW_ORG_NAME}OrdererMSP.json ./org-temp
    cp ${NEW_ORG_NAME}MSP.json ./org-temp
    cp server.crt ./org-temp

    pushd $ORG_DIRECTORY/org-temp

    # Add to channel
    fetchConfigBlock
    addOrgChannel
    sendUpdate

    popd

elif [ $OPERATION == "remove" ]; then
    peerEnvVariables
    mkdir $ORG_DIRECTORY/org-temp
    pushd $ORG_DIRECTORY/org-temp

    # Remove from channel
    fetchConfigBlock
    removeOrgChannel
    sendUpdate

    popd
fi