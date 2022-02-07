#!/bin/bash

PORT=26818
RPCPORT=26817
CONF_DIR=~/.mnpostree

cd ~
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
if [[ $(lsb_release -d) = *16.04* ]]; then
  COINZIP='https://github.com/mnpostree/mptcoin/releases/download/v1.2/MPTC_v1.2.0.0_ubuntu16.zip'
fi
if [[ $(lsb_release -d) = *18.04* ]]; then
  COINZIP='https://github.com/mnpostree/mptcoin/releases/download/v1.2/MPTC_v1.2.0.0_ubuntu18.zip'
fi
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

function configure_systemd {
  cat << EOF > /etc/systemd/system/mnpostree.service
[Unit]
Description=MNPoSTree Coin Service
After=network.target
[Service]
User=root
Group=root
Type=forking
ExecStart=/usr/local/bin/mnpostreed
ExecStop=-/usr/local/bin/mnpostree-cli stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  sleep 6
  crontab -l > crontmp
  echo "@reboot systemctl start mnpostree" >> crontmp
  crontab crontmp
  rm crontmp
  systemctl start mnpostree.service
}

echo ""
echo ""
DOSETUP="y"

if [ $DOSETUP = "y" ]  
then
  sudo apt-get update
  sudo apt-get -y upgrade
  sudo apt-get -y dist-upgrade
  sudo apt-get update
  sudo apt-get update && apt-get dist-upgrade -y && apt install nano htop -y && apt-get install build-essential libtool autotools-dev autoconf pkg-config libssl-dev -y && apt-get install libboost-all-dev git libminiupnpc-dev -y && apt-get install software-properties-common -y && apt install -y make build-essential libtool software-properties-common autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git curl bsdmainutils libminiupnpc-dev libgmp3-dev pkg-config libevent-dev unzip && sudo add-apt-repository ppa:bitcoin/bitcoin -y && sudo apt-get update -y && sudo apt-get install libdb4.8-dev libdb4.8++-dev -y && sudo apt-get install make automake cmake curl g++-multilib libtool binutils-gold bsdmainutils pkg-config python3 -y && sudo apt-get install curl librsvg2-bin libtiff-tools bsdmainutils cmake imagemagick libcap-dev libz-dev libbz2-dev python-setuptools -y && apt-get install libzmq3-dev -y && apt-get install libdb5.3++-dev iotop -y && sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y && sudo apt-get update -y && sudo apt-get upgrade libstdc++6 -y

  cd /var
  sudo touch swap.img
  sudo chmod 600 swap.img
  sudo dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
  sudo mkswap /var/swap.img
  sudo swapon /var/swap.img
  sudo free
  sudo echo "/var/swap.img none swap sw 0 0" >> /etc/fstab
  cd
  
  cd /usr/local/bin/
  wget $COINZIP
  unzip *.zip
  chmod +x mnpostree*
  rm mnpostree-qt mnpostree-tx *.zip
  
  mkdir -p $CONF_DIR
  cd $CONF_DIR
  wget http://cdn.delion.xyz/mptc.zip
  unzip mptc.zip
  rm mptc.zip

fi

 IP=$(curl -s4 api.ipify.org)
 echo ""
 echo "Configure your masternodes now!"
 echo "Detecting IP address:$IP"
 echo ""
 echo "Enter masternode private key"
 read PRIVKEY
 
  echo "rpcuser=user"`shuf -i 100000-10000000 -n 1` >> mnpostree.conf_TEMP
  echo "rpcpassword=pass"`shuf -i 100000-10000000 -n 1` >> mnpostree.conf_TEMP
  echo "rpcallowip=127.0.0.1" >> mnpostree.conf_TEMP
  echo "rpcport=$RPCPORT" >> mnpostree.conf_TEMP
  echo "listen=1" >> mnpostree.conf_TEMP
  echo "server=1" >> mnpostree.conf_TEMP
  echo "daemon=1" >> mnpostree.conf_TEMP
  echo "maxconnections=250" >> mnpostree.conf_TEMP
  echo "masternode=1" >> mnpostree.conf_TEMP
  echo "dbcache=20" >> mnpostree.conf_TEMP
  echo "maxorphantx=5" >> mnpostree.conf_TEMP
  echo "maxmempool=100" >> mnpostree.conf_TEMP
  echo "" >> mnpostree.conf_TEMP
  echo "port=$PORT" >> mnpostree.conf_TEMP
  echo "externalip=$IP:$PORT" >> mnpostree.conf_TEMP
  echo "masternodeaddr=$IP:$PORT" >> mnpostree.conf_TEMP
  echo "masternodeprivkey=$PRIVKEY" >> mnpostree.conf_TEMP
  mv mnpostree.conf_TEMP mnpostree.conf
  cd
  echo ""
  echo -e "Your ip is ${GREEN}$IP:$PORT${NC}"

	## Config Systemctl
	configure_systemd
  
echo ""
echo "Commands:"
echo -e "Start MNPoSTree Service: ${GREEN}systemctl start mnpostree${NC}"
echo -e "Check MNPoSTree Status Service: ${GREEN}systemctl status mnpostree${NC}"
echo -e "Stop MNPoSTree Service: ${GREEN}systemctl stop mnpostree${NC}"
echo -e "Check Masternode Status: ${GREEN}mnpostree-cli getmasternodestatus${NC}"

echo ""
echo -e "${GREEN}MNPoSTree Masternode Installation Done${NC}"
exec bash
exit
