sudo apt install git

sudo apt install curl

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io

sudo groupadd docker

sudo usermod -aG docker $USER

sudo curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

sudo apt update

sudo apt -y install curl dirmngr apt-transport-https lsb-release ca-certificates

curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -

sudo apt -y install nodejs

sudo apt-get install npm

sudo npm install -g npm@latest 

wget https://dl.google.com/go/go1.11.12.linux-amd64.tar.gz

sudo tar -C /usr/local -xzf go1.11.12.linux-amd64.tar.gz

rm go1.11.12.linux-amd64.tar.gz

curl -sSL https://bit.ly/2ysbOFE | bash -s