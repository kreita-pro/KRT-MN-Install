#!/bin/bash
clear

# Check if we are root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root." 1>&2
   exit 1
fi

# Check if we have enough memory
if [[ `free -m | awk '/^Mem:/{print $2}'` -lt 900 ]]; then
  echo "This installation requires at least 1GB of RAM.";
  exit 1
fi

# Check if we have enough disk space
if [[ `df -k --output=avail / | tail -n1` -lt 10485760 ]]; then
  echo "This installation requires at least 10GB of free disk space.";
  exit 1
fi

# Install tools for dig and systemctl
echo "Preparing installation..."
apt-get install git dnsutils systemd -y > /dev/null 2>&1

# Check for systemd
#systemctl --version >/dev/null 2>&1 || { echo "systemd is required. Are you using Ubuntu 16.04?"  >&2; exit 1; }

# CHARS is used for the loading animation further down.
CHARS="/-\|"
EXTERNALIP=`dig +short myip.opendns.com @resolver1.opendns.com`

clear


echo "
    ___T_
   | o o |
   |__-__|
   /| []|\\
 ()/|___|\()
    |_|_|
    /_|_\  ------- MASTERNODE INSTALLER v2.6 -------+
 |                                                |
 | HTRCv1.0.2.0-60031 Installer by Kurbz          |
 | for Ununtu 16.04 only                          |
 |                                                |::
 +------------------------------------------------+::
   ::::::::::::::::::::::::::::::::::::::::::::::::::
"

sleep 2

USER=root

USERHOME=`eval echo "~$USER"`

read -e -p "Server IP Address: " -i $EXTERNALIP -e IP
read -e -p "Masternode Private Key: " KEY


clear

# Generate random passwords
RPCUSER=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
RPCPASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

# update packages and upgrade Ubuntu
echo "Installing dependencies..."
apt-get -qq update
apt-get -qq upgrade
apt-get -qq autoremove
apt-get -qq install wget htop unzip
apt-get install systemd -y
apt-get update 
apt-get -y install libdb++-dev 
apt-get -y install libboost-all-dev 
apt-get -y install libcrypto++-dev 
apt-get -y install libqrencode-dev 
apt-get -y install libminiupnpc-dev 
apt-get -y install libgmp-dev 
apt-get -y install libgmp3-dev 
apt-get -y install autoconf 
apt-get -y install autogen 
apt-get -y install automake 
apt-get -y install bsdmainutils 
apt-get -y install libzmq3-dev 
apt-get -y install libminiupnpc-dev 
apt-get -y install libevent-dev
add-apt-repository -y ppa:bitcoin/bitcoin
apt-get update
apt-get install -y libdb4.8-dev libdb4.8++-dev
apt-get -qq install aptitude
apt-get update


aptitude -y -q install fail2ban
service fail2ban restart
apt-get -qq install ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 11368/tcp
ufw allow 11369/tcp
yes | ufw enable


echo "
**********Installing deamon***********
"
sleep 2
wget https://github.com/htrcoin/htrcoin/releases/download/v1020/HTRC_Headless_Linux_v1020.zip
unzip HTRC_Headless_Linux_v1020.zip
cp /root/linux/hightemperatured /usr/local/bin
chmod +x /usr/local/bin/hightemperatured 
cp /root/linux/hightemperatured /root/
chmod +x /usr/local/bin/hightemperatured 

echo "
*********Configuring confs***********
"
sleep 2
mkdir $USERHOME/.HighTemperature

# Create hightemperature.conf
touch $USERHOME/.HighTemperature/HighTemperature.conf
cat > $USERHOME/.HighTemperature/HighTemperature.conf << EOL
rpcuser=${RPCUSER}
rpcpassword=${RPCPASSWORD}
rpcallowip=127.0.0.1
rpcport=11369
port=11368
listen=1
server=1
daemon=1
gen=1
logtimestamps=1
maxconnections=256
externalip=${IP}
bind=${IP}:11368
masternodeaddr=${IP}
masternodeprivkey=${KEY}
masternode=1
addnode=45.76.37.60:11368
addnode=1.160.157.57:11368
addnode=186.113.245.245:11368
addnode=85.247.171.175:11368
addnode=83.213.187.72:11368
addnode=104.168.52.146:11368
addnode=98.24.33.121:11368
addnode=79.184.123.19:11368
addnode=34.207.125.26:11368
addnode=45.77.147.113:11368
addnode=149.28.32.21:11368
addnode=107.191.58.52:11368
addnode=159.65.66.83:11368
addnode=104.238.167.55:11368
addnode=46.160.207.24:11368
addnode=188.27.201.93:11368
addnode=149.28.74.224:11368
addnode=95.216.33.107:11368
addnode=54.37.232.179:11368
addnode=108.160.130.198:11368
EOL
chmod 0600 $USERHOME/.HighTemperature/HighTemperature.conf
chown -R $USER:$USER $USERHOME/.HighTemperature

sleep 1

cat > /etc/systemd/system/hightemperatured.service << EOL
[Unit]
Description=hightemperatured
After=network.target
[Service]
Type=forking
User=${USER}
WorkingDirectory=${USERHOME}
ExecStart=/usr/local/bin/hightemperatured -conf=${USERHOME}/.HighTemperature/HighTemperature.conf -datadir=${USERHOME}/.HighTemperature
ExecStop=/usr/local/bin/hightemperatured -conf=${USERHOME}/.HighTemperature/HighTemperature.conf -datadir=${USERHOME}/.HighTemperature stop
Restart=on-abort
[Install]
WantedBy=multi-user.target
EOL

chmod +x /usr/local/bin/hightemperatured 
sudo ln -s /usr/lib/x86_64-linux-gnu/libboost_system.so.1.58.0 /usr/lib/x86_64-linux-gnu/libboost_program_options.so.1.54.0
#start service
echo "
********Starting Service*************
"
sleep 3
sudo systemctl enable hightemperatured
sudo systemctl start hightemperatured
sudo systemctl start hightemperatured.service

#clear

echo "Service Started... Press any key to continue. "

#clear

echo "Your masternode is syncing. Please wait for this process to finish. "

until su -c "hightemperatured masternode status 2>/dev/null | grep 'Masternode Running Remotly' > /dev/null" $USER; do
  for (( i=0; i<${#CHARS}; i++ )); do
    sleep 5
    #echo -en "${CHARS:$i:1}" "\r"
    clear
    echo "Service Started. Your masternode is syncing. 
    When Current = Synced then select your MN in the local wallet and start it."
    echo "Current Block: "
    su -c "curl http://explorer.htrcoin.com/api/getblockcount" $USER
    echo "Synced Blocks: "
    su -c "hightemperatured getblockcount" $USER
  done
done

su -c "/usr/local/bin/hightemperatured masternode status" $USER

#sleep 1
#su -c "/usr/local/bin/hightemperatured masternode start" $USER
#sleep 1
#clear
#su -c "/usr/local/bin/hightemperatured masternode status" $USER
#sleep 5

#echo "" && echo "Masternode setup completed." && echo ""
