#!/bin/bash

####### 参数解析 #######
cmdname=$(basename $0)
init=false

# usage help doc.
usage() {
    cat << USAGE  >&2
Usage:
    $cmdname [-i]
    -i         Init the run env. It will generate a uuid and replace config files with this uuid.
    -h         Show help info.
USAGE
    exit 1
}

while getopts ih OPT;do
    case $OPT in
        i)
            init=true
            ;;
        h)
            usage
            exit 2
            ;;
        \?)
            usage
            exit 3
            ;;
    esac
done

if [ "$init"x = "truex" ] ; then
    # generate new uuid
    new_uuid_tcp=$(cat /proc/sys/kernel/random/uuid)
    new_uuid_ws_tls=$(cat /proc/sys/kernel/random/uuid)
    new_ss_pwd=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 24 | head -n 1)

    # cp files
    cp -fv Caddyfile.template Caddyfile
    cp -fv v2ray-config.json.template v2ray-config.json
    cp -fv  docker-compose.yml.template docker-compose.yml

    # replace v2ray server config
    sed -i -e 's/{UUID_PLACE_HOLDER_TCP}/'"$new_uuid_tcp"'/g' v2ray-config.json
    sed -i -e 's/{UUID_PLACE_HOLDER_WS_TLS}/'"$new_uuid_ws_tls"'/g' v2ray-config.json
    sed -i -e 's/{SS_PASSWORD}/'"$new_ss_pwd"'/g' v2ray-config.json

    # read domain and email from user input
    read -p "Domain for caddy : " domain
    read -p "Email for CloudFlare : " mail
    read -p "CloudFlare Global API Key  : " cf_api_key

    # replace domain and mail int Caddyfile
    sed -i -e 's/{DOMAIN}/'"$domain"'/g' Caddyfile
    sed -i -e 's/{MAIL}/'"$mail"'/g' docker-compose.yml
    sed -i -e 's/{CF_API_KEY}/'"$cf_api_key"'/g' docker-compose.yml

    # output uuid
    echo "V2ray will start WS+TLS at domain $domain with new UUID : $new_uuid_ws_tls"
    echo "V2ray will start TCP with new UUID : $new_uuid_tcp"
    echo "V2ray will start SS with password  : $new_ss_pwd"
fi

# start caddy + v2ray
docker-compose down
docker-compose up -d



