#!/bin/bash -e

# `init` hook
# $1 = operation (either `join`, `boot` or `orchestrate`)

echo "Starting $1 operation"

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