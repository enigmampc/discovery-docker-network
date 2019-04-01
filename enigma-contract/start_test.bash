#!/bin/bash
cd /root/enigma-contract/enigma-js

echo "Waiting for p2p-worker..."
until curl -s -m 1 p2p-worker:3346; do sleep 5; done

echo "Waiting for p2p-worker to register..."
sleep 7

proxy=$(getent hosts p2p-proxy | awk '{ print $1 }')
contract=$(getent hosts contract | awk '{ print $1 }')
contractaddress=$(curl -s http://contract:8081)
tokenaddress=$(curl -s http://contract:8082)

for filename in test/integrationTests/template.*; do 
	sed -e "s_http://[localhost|.0-9]*:3346_http://$proxy:3346_" $filename > $(echo $filename | sed "s/template\.\(.*\).js/\1.spec.js/")
    sed -i "s_http://[localhost|.0-9]*:9545_http://$contract:9545_" $(echo $filename | sed "s/template\.\(.*\).js/\1.spec.js/")
	sed -i "s/EnigmaContract.networks\['4447'\].address/'$contractaddress'/" $(echo $filename | sed "s/template\.\(.*\).js/\1.spec.js/")
	sed -i "s/EnigmaTokenContract.networks\['4447'\].address/'$tokenaddress'/" $(echo $filename | sed "s/template\.\(.*\).js/\1.spec.js/")
done

if yarn test:integration 01_init.spec.js; then
	yarn test:integration 02_deploy.spec.js
	yarn test:integration 10_execute.spec.js
fi
