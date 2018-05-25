echo "1.5"
rm *
echo rm ./krtd
echo rm -rf ./.krt
echo rm /usr/local/bin/krtd
echo rm /usr/local/bin/krtcli
echo "

**********Installing deamon***********

"
sleep 2
wget  https://github.com/kreita-pro/krt/releases/download/v1.2.2.3/krtd-Linux64
wget https://github.com/kreita-pro/krt/releases/download/v1.2.2.3/krt-cli-Linux64
mv ./krtd-Linux64 /usr/local/bin/krtd
mv ./krt-cli-Linux64 /usr/local/bin/krtcli
mv ./krtd-Linux64 krtd
mv ./krt-cli-Linux64 krtcli

chmod +x /usr/local/bin/krtd
chmod +x ./krtd
chmod +x /usr/local/bin/krtdcli
chmod +x ./krtcli
echo "

*********Configuring confs***********

"
sleep 2
mkdir $USERHOME/.krt

# Create hightemperature.conf
touch $USERHOME/.krt/krt.conf
cat > $USERHOME/.krt/krt.conf << EOL
rpcuser=${RPCUSER}
rpcpassword=${RPCPASSWORD}
rpcallowip=127.0.0.1
rpcport=47048
port=47047
listen=1
server=1
daemon=1
listenonion=0
logtimestamps=1
maxconnections=256
externalip=${IP}
bind=${IP}:47047
masternodeaddr=${IP}
masternodeprivkey=${KEY}
masternode=1

EOL
chmod 0600 $USERHOME/.krt/krt.conf
chown -R $USER:$USER $USERHOME/.krt

sleep 1

cat > /etc/systemd/system/krtd.service << EOL
[Unit]
Description=krtd
After=network.target
[Service]
Type=forking
User=${USER}
WorkingDirectory=${USERHOME}
ExecStart=/usr/local/bin/krtd -conf=${USERHOME}/.krt/krt.conf -datadir=${USERHOME}/.krt
ExecStop=/usr/local/bin/krtcli -conf=${USERHOME}/.krt/krt.conf -datadir=${USERHOME}/.krt stop
Restart=on-abort
[Install]
WantedBy=multi-user.target
EOL

chmod +x /usr/local/bin/krtd 
chmod +x /usr/local/bin/krtdcli
sudo ln -s /usr/lib/x86_64-linux-gnu/libboost_system.so.1.58.0 /usr/lib/x86_64-linux-gnu/libboost_program_options.so.1.54.0
#start service
echo "

********Starting Service*************


"
sleep 3
sudo systemctl enable krtd
sudo systemctl start krtd
sudo systemctl start krtd.service

#clear

echo "Service Started... Press any key to continue. "

#clear

echo "Your masternode is syncing. Please wait for this process to finish. "

until su -c "krtcli startmasternode local false 2>/dev/null | grep 'successfully started' > /dev/null" $USER; do
  for (( i=0; i<${#CHARS}; i++ )); do
    sleep 5
    #echo -en "${CHARS:$i:1}" "\r"
    clear
    echo "Service Started. Your masternode is syncing. 
    When Current = Synced then select your MN in the local wallet and start it."
    echo "Current Block: "
    su -c "curl http://explorer.kreita.io/api/getblockcount" $USER
    echo "Synced Blocks: "
    su -c "krtcli getblockcount" $USER
  done
done

su -c "/usr/local/bin/krtcli startmasternode local false" $USER

sleep 1
su -c "/usr/local/bin/krtcli masternode status" $USER
sleep 1
#clear
#su -c "/usr/local/bin/krtd masternode status" $USER
#sleep 5

echo "" && echo "Masternode setup completed." && echo ""
