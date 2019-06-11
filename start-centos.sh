#!/bin/bash

# 修改v2ray的 uuid
new_uuid=`uuidgen`
sed -i -e 's/{UUID_PLACE_HOLDER}/'"$new_uuid"'/g' server/config.json
sed -i -e 's/{UUID_PLACE_HOLDER}/'"$new_uuid"'/g' client/config-win.json
sed -i -e 's/{UUID_PLACE_HOLDER}/'"$new_uuid"'/g' client/config.json

# read domain

read -p "domain for caddy : " domain
read -p "email for tls : " mail

sed -i -e 's/{DOMAIN}/'"$domain"'/g' Caddyfile
sed -i -e 's/{DOMAIN}/'"$domain"'/g' client/config-win.json
sed -i -e 's/{DOMAIN}/'"$domain"'/g' client/config.json

sed -i -e 's/{MAIL}/'"$mail"'/g' Caddyfile

docker-compose up -d

echo "v2ray started an $domain with new UUID : $new_uuid"
echo "copy client config file into local v2ray"
