#!/bin/bash
rm -rf /root/.enigma/*

LD_LIBRARY_PATH=/opt/intel/libsgx-enclave-common/aesm /opt/intel/libsgx-enclave-common/aesm/aesm_service &
sleep 5 # give time to aesm_service to start
cp principal_test_config.json /root/enigma-core/enigma-principal/app/tests/principal_node/config

pushd /root/enigma-core/enigma-principal/bin
. /opt/sgxsdk/environment && . /root/.cargo/env && RUST_BACKTRACE=1 ./enigma-principal-app -w
popd

contract=$(getent hosts contract | awk '{ print $1 }')

echo "Waiting for contracts to be deployed..."
until curl -s -m 1 contract:8081 >/dev/null 2>&1; do sleep 1; done
contractaddress=$(curl -s http://contract:8081 | sed "s/^0x//")

sed -i "s_http://[localhost|.0-9]*:9545_http://$contract:9545_" principal_test_config.json
sed -i "s/\(\"enigma_contract_address\":\) \"[0-9a-fA-F]*\"/\1 \"$contractaddress\"/" principal_test_config.json

sed -i "s_5aeda56215b167893e80b4fe645ba6d5bab767de_1df62f291b2e969fb0849d99d9ce41e2f137006e_" /root/enigma-core/enigma-principal/app/tests/principal_node/config/deploy_config.json

cp principal_test_config.json /root/enigma-core/enigma-principal/app/tests/principal_node/config

cd /root/enigma-core/enigma-principal/bin
RUST_BACKTRACE=1 ./enigma-principal-app
