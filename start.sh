#!/bin/bash

# generate new uuid
new_uuid=$(cat /proc/sys/kernel/random/uuid)


sed -i -e 's/{UUID_PLACE_HOLDER}/'"$new_uuid"'/g' v2ray-config.json

# read domain and email from user input
read -p "Domain for caddy : " domain
read -p "Email for tls : " mail

# replace domain and mail int Caddyfile
sed -i -e 's/{DOMAIN}/'"$domain"'/g' Caddyfile
sed -i -e 's/{MAIL}/'"$mail"'/g' Caddyfile

# start caddy + v2ray
docker-compose down
docker-compose up -d

# output uuid
echo "v2ray started an $domain with new UUID : $new_uuid"
