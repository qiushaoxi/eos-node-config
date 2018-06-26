echo "Load env config"
source set-env.sh

docker stop bpnode-$stage_name || true
docker rm bpnode-$stage_name || true

docker -H $fullnode1_ip:5555 stop fullnode-$stage_name || true
docker -H $fullnode1_ip:5555 rm fullnode-$stage_name || true

docker -H $fullnode2_ip:5555 stop fullnode-$stage_name || true
docker -H $fullnode2_ip:5555 rm fullnode-$stage_name || true

docker -H $fullnode3_ip:5555 stop fullnode-$stage_name || true
docker -H $fullnode3_ip:5555 rm fullnode-$stage_name || true


rm -rf script
mkdir script

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
                            --delete-all-blocks " > script/join.sh

echo "docker stop fullnode-$stage_name
    docker rm -f fullnode-$stage_name
    docker run -ti --detach --name fullnode-$stage_name \
       -v $eos_config_dir/$stage_name:/etc/nodeos -v $eos_data_dir/$stage_name:/data \
       -p $http_port:8888 -p $p2p_port:9876 \
       $docker_tag \
       /opt/eosio/bin/nodeos --data-dir=/data \
                             --config-dir=/etc/nodeos " > script/restart.sh

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
put `pwd`/script/* $eos_config_dir/$stage_name
quit
EOF

sftp $fullnode2_username@$fullnode2_ip << EOF
mkdir $eos_config_dir/$stage_name
put `pwd`/script/* $eos_config_dir/$stage_name
quit
EOF

sftp $fullnode3_username@$fullnode3_ip << EOF
mkdir $eos_config_dir/$stage_name
put `pwd`/script/* $eos_config_dir/$stage_name
quit
EOF


echo "Running 'fullnode1' through Docker."
docker -H $fullnode1_ip:5555 run -ti --detach --name fullnode-$stage_name \
       -v $eos_config_dir/$stage_name:/etc/nodeos -v $eos_data_dir/$stage_name:/data \
       -p $http_port:8888 -p $p2p_port:9876 \
       $docker_tag \
       /opt/eosio/bin/nodeos --data-dir=/data \
                             --config-dir=/etc/nodeos 
echo ""
echo "Running 'fullnode2' through Docker."
docker -H $fullnode2_ip:5555 run -ti --detach --name fullnode-$stage_name \
       -v $eos_config_dir/$stage_name:/etc/nodeos -v $eos_data_dir/$stage_name:/data \
       -p $http_port:8888 -p $p2p_port:9876 \
       $docker_tag \
       /opt/eosio/bin/nodeos --data-dir=/data \
                             --config-dir=/etc/nodeos 
echo ""
echo "Running 'fullnode3' through Docker."
docker -H $fullnode3_ip:5555 run -ti --detach --name fullnode-$stage_name \
       -v $eos_config_dir/$stage_name:/etc/nodeos -v $eos_data_dir/$stage_name:/data \
       -p $http_port:8888 -p $p2p_port:9876 \
       $docker_tag \
       /opt/eosio/bin/nodeos --data-dir=/data \
                             --config-dir=/etc/nodeos \
                             --delete-all-blocks 
echo ""

echo "Running 'nodeos' through Docker."
docker run -ti --detach --name bpnode-$stage_name \
       -v `pwd`:/etc/nodeos -v $eos_data_dir/$stage_name:/data \
       -p $http_port:8888 -p $p2p_port:9876 \
       $docker_tag \
       /opt/eosio/bin/nodeos --data-dir=/data \
                             --config-dir=/etc/nodeos 


echo ""
echo "   View logs with: docker logs -f nodeos-bios"
echo ""

echo "Waiting 3 secs for nodeos to launch through Docker"
sleep 3

echo "Hit ENTER to continue"
read
