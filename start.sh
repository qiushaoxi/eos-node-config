# read key
echo "publickKey:"
read publickKey
echo "privateKey:"
read privateKey

echo "Load env config"
source set-env.sh

docker kill bpnode-$stage_name || true
docker rm bpnode-$stage_name || true

docker -H $fullnode1_ip:5555 kill fullnode-$stage_name || true
docker -H $fullnode1_ip:5555 rm fullnode-$stage_name || true

docker -H $fullnode2_ip:5555 kill fullnode-$stage_name || true
docker -H $fullnode2_ip:5555 rm fullnode-$stage_name || true

docker -H $fullnode3_ip:5555 kill fullnode-$stage_name || true
docker -H $fullnode3_ip:5555 rm fullnode-$stage_name || true


echo "Copying base config"
cp base_config.ini config.ini


cat p2p-peer-address >> config.ini
echo "plugin = eosio::producer_api_plugin" >> config.ini

# add none bp fullnode
rm -rf fullnode
mkdir fullnode
cp base_config.ini fullnode/config.ini
cp genesis.json fullnode/genesis.json
cat p2p-peer-address >> config.ini
echo "" >> config.ini
echo "p2p-peer-address = $bpnode_ip:$p2p_port" >> config.ini
echo "p2p-peer-address = $fullnode1_ip:$p2p_port" >> config.ini
echo "p2p-peer-address = $fullnode2_ip:$p2p_port" >> config.ini
echo "p2p-peer-address = $fullnode3_ip:$p2p_port" >> config.ini
cp config.ini fullnode/config.ini

echo "producer-name = eosecosystem" >> config.ini
echo "private-key = [\"$publickKey\",\"$privateKey\"]" >> config.ini
echo "plugin = eosio::producer_api_plugin" >> config.ini

# add restart and join scripte
echo "docker rm -f fullnode-$stage_name
    docker run -ti --detach --name fullnode-$stage_name \
       -v $eos_config_dir/$stage_name:/etc/nodeos -v $eos_data_dir/$stage_name:/data \
       -p $http_port:8888 -p $p2p_port:9876 \
       $docker_tag \
       /opt/eosio/bin/nodeos --data-dir=/data \
                             --config-dir=/etc/nodeos \
                             --delete-all-blocks \
                             --genesis-json=/etc/nodeos/genesis.json \
                            --delete-all-blocks " > fullnode/join.sh

echo "docker stop fullnode-$stage_name
    docker rm -f fullnode-$stage_name
    docker run -ti --detach --name fullnode-$stage_name \
       -v $eos_config_dir/$stage_name:/etc/nodeos -v $eos_data_dir/$stage_name:/data \
       -p $http_port:8888 -p $p2p_port:9876 \
       $docker_tag \
       /opt/eosio/bin/nodeos --data-dir=/data \
                             --config-dir=/etc/nodeos " > fullnode/restart.sh

echo "docker run -ti --detach --name bpnode-$stage_name \
       -v `pwd`:/etc/nodeos -v $eos_data_dir/$stage_name:/data \
       -p $http_port:8888 -p $p2p_port:9876 \
       $docker_tag \
       /opt/eosio/bin/nodeos --data-dir=/data \
                             --config-dir=/etc/nodeos \
                             --genesis-json=/etc/nodeos/genesis.json \
                             --delete-all-blocks" > join.sh

echo "docker stop bpnode-$stage_name
    docker rm -f bpnode-$stage_name
    docker run -ti --detach --name bpnode-$stage_name \
       -v `pwd`:/etc/nodeos -v $eos_data_dir/$stage_name:/data \
       -p $http_port:8888 -p $p2p_port:9876 \
       $docker_tag \
       /opt/eosio/bin/nodeos --data-dir=/data \
                             --config-dir=/etc/nodeos" > restart.sh


# sftp put config file to fullnode
sftp $fullnode1_username@$fullnode1_ip << EOF
mkdir $eos_config_dir/$stage_name
put `pwd`/fullnode/* $eos_config_dir/$stage_name
quit
EOF

sftp $fullnode2_username@$fullnode2_ip << EOF
mkdir $eos_config_dir/$stage_name
put `pwd`/fullnode/* $eos_config_dir/$stage_name
quit
EOF

sftp $fullnode3_username@$fullnode3_ip << EOF
mkdir $eos_config_dir/$stage_name
put `pwd`/fullnode/* $eos_config_dir/$stage_name
quit
EOF


echo "Running 'fullnode1' through Docker."
docker -H $fullnode1_ip:5555 run -ti --detach --name fullnode-$stage_name \
       -v $eos_config_dir/$stage_name:/etc/nodeos -v $eos_data_dir/$stage_name:/data \
       -p $http_port:8888 -p $p2p_port:9876 \
       $docker_tag \
       /opt/eosio/bin/nodeos --data-dir=/data \
                             --config-dir=/etc/nodeos \
                             --delete-all-blocks \
                             --genesis-json=/etc/nodeos/genesis.json 
echo ""
echo "Running 'fullnode2' through Docker."
docker -H $fullnode2_ip:5555 run -ti --detach --name fullnode-$stage_name \
       -v $eos_config_dir/$stage_name:/etc/nodeos -v $eos_data_dir/$stage_name:/data \
       -p $http_port:8888 -p $p2p_port:9876 \
       $docker_tag \
       /opt/eosio/bin/nodeos --data-dir=/data \
                             --config-dir=/etc/nodeos \
                             --delete-all-blocks \
                             --genesis-json=/etc/nodeos/genesis.json 
echo ""
echo "Running 'fullnode3' through Docker."
docker -H $fullnode3_ip:5555 run -ti --detach --name fullnode-$stage_name \
       -v $eos_config_dir/$stage_name:/etc/nodeos -v $eos_data_dir/$stage_name:/data \
       -p $http_port:8888 -p $fp2p_port:9876 \
       $docker_tag \
       /opt/eosio/bin/nodeos --data-dir=/data \
                             --config-dir=/etc/nodeos \
                             --delete-all-blocks \
                             --genesis-json=/etc/nodeos/genesis.json 
echo ""

echo "Running 'nodeos' through Docker."
docker run -ti --detach --name bpnode-$stage_name \
       -v `pwd`:/etc/nodeos -v $eos_data_dir/$stage_name:/data \
       -p $http_port:8888 -p $p2p_port:9876 \
       $docker_tag \
       /opt/eosio/bin/nodeos --data-dir=/data \
                             --config-dir=/etc/nodeos \
                             --delete-all-blocks \
                             --genesis-json=/etc/nodeos/genesis.json


echo ""
echo "   View logs with: docker logs -f nodeos-bios"
echo ""

echo "Waiting 3 secs for nodeos to launch through Docker"
sleep 3

echo "Hit ENTER to continue"
read
