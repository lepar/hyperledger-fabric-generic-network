# hyperledger-fabric-generic-network

A simple and generic hyperledger fabric network that runs with Raft consensus and TLS enabled.
It deploys a network with:

    - 1 Certificate Authority
    - 3 orderers for the raft consensus to work nicely
    - 1 Peer
    - 1 CouchDB
    - 1 CLI

Pre Requisites:
Refer to https://hyperledger-fabric.readthedocs.io/en/release-1.4/prereqs.html

Requires versions 8.10 of node and 5.5.1 npm to be installed

This network works only on Fabric 1.4.3 and it is up to production standards using Raft and TLS for secure communication

To deploy a network simply run the command "./deploy.sh" in your terminal and tpye in the following information
as it asks you in an interactive mode:

    - Organization Name
    - Organization Domain
    - Host computers IP Address

Example:
./deploy.sh

Organization Name: Org1

Organization Domain: org1.com

Computer IP Address: 192.168.0.0

To get the host computers ip address, you can run "hostname -I"

If you encounter the error

"Error: could not assemble transaction, err proposal response was not successful, error code 500, msg error starting container: error starting container: API error (404): network hyperledger-fabric-generic-network_fabric not found"

Then you must change the environment variable in the Peer Service in the the docker-compose.yml

      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=hyperledgerfabricgenericnetwork_fabric

Add or Remove Organization Script

File: add-remove-org.sh

This file adds an organization or removes it from a given channel. There are three files required:

    - server.crt (The new organizations orderer tls)

    - newOrg.json (The json that contains the new organizations peer's public keys, generated by the command "configtxgen -printOrg")

    - newOrgORderer.json (The json that contains the new organizations orderer's public keys, generated by the command "configtxgen -printOrg")

The script must be run from within the CLI container and the three files in the same root folder as the script file.

To add an organization, run the script with the following parameters:

    - ./add-remove-org.sh add ORG_NAME ORG_IP admin_org_domain CHANNEL_NAME AdminOrgName

To remove an organization

    - ./add-remove-org.sh remove ORG_NAME ORG_IP admin_org_domain CHANNEL_NAME AdminOrgName

Node Client

The node client is used to transact with the network using POST requests

The first step is to enroll the admin 

Endpoint: http://localhost:3000/enrollAdmin

The second step is to register a user to interact with the network

Endpoint:  http://localhost:3000/registerUser


JSON payload to send:

{
    "user": "userName"
}

There are two functions currently implemented:

Invoke the chaincode and create a transaction in the network

Endpoint:  http://localhost:3000/invoke

JSON Payload to send:

{
    "user": "userName",
    "key": "KeyForData",
    "data": "any data"
}

Query the blockchain

Endpoint:  http://localhost:3000/query

{
    "user": "userName",
    "key": "KeyForData",
}


I am not responsible for the misuse of this generic code nor any damages that may occurr from improper use or development.
This code is open source and free for anyone to use for any type of project or application under the Apache-2.0 license

Feel free to email me with questions or suggestions

Contact:
nlzanutim@yahoo.com

Donations are welcome as I intend on continuing to contribute to the community

Bitcoin: bc1qndlhlznpcqp63hacj4w28ph6vxjzua942ftqse

Litecoin: ltc1q2vzn2ztts5lf8am4h5paukjv8xha5ajte8rpg2

Monero: 45yWqAH7ynhGUXtwx2nuNn14avPXNcdTwfa1aWbU5tbm1oBtiVCLo4fSD83nG6K5JeC1kwtLRbWqsadtCuodXeYnStbMtGw

Dogecoin: DR6tUDs8YKbfqiRSwtN5fXATr9YNHGbXQY

Ethereum: 0x4F6e88c170F438EC2529f6bbA921c0236b3b45c4
