sample config of eos-bios.

run bp in private net.

publish fullnode to internet.


1. vim set-env.sh
2. source set-env.sh
3. vim seed_network.keys
4. vim hook_join_network.sh
5. vim my_discovery_file.yaml
6. eos-bios *


## docker
docker build -t qiushaoxi/eosio:v1.0.0 --build-arg branch=v1.0.0  --build-arg symbol=EOS .
