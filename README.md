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
Requires the latest versions of node and npm to be installed

This network works only on Fabric 1.4.3 and it is up to production standards using Raft and TLS for secure communication

To deploy a network simply run deploy.sh with 3 parameters:

    - Organization Name
    - Organization Domain 
    - Host computers IP Address

Example:
./deploy.sh Org1 org1.com 192.168.0.0

To get the host computers ip address, you can run "hostname -I"

I am not responsible for the misuse of this generic code nor any damages that may occurr from improper use or development. 
This code is open source and free for anyone to use for any type of project or application.
Feel free to email me with questions or suggestions

Contact:
nlzanutim@yahoo.com

Donations are welcome as I intend on continuing to contribute to the community


Bitcoin: bc1qndlhlznpcqp63hacj4w28ph6vxjzua942ftqse


Litecoin: ltc1q2vzn2ztts5lf8am4h5paukjv8xha5ajte8rpg2


Monero: 45yWqAH7ynhGUXtwx2nuNn14avPXNcdTwfa1aWbU5tbm1oBtiVCLo4fSD83nG6K5JeC1kwtLRbWqsadtCuodXeYnStbMtGw


Dogecoin: DR6tUDs8YKbfqiRSwtN5fXATr9YNHGbXQY


Ethereum: 0x4F6e88c170F438EC2529f6bbA921c0236b3b45c4