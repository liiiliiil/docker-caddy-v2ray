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
    new_uuid=$(cat /proc/sys/kernel/random/uuid)

    # replace v2ray server config
    sed -i -e 's/{UUID_PLACE_HOLDER}/'"$new_uuid"'/g' v2ray-config.json

    # read domain and email from user input
    read -p "Domain for caddy : " domain
    read -p "Email for tls : " mail

    # replace domain and mail int Caddyfile
    sed -i -e 's/{DOMAIN}/'"$domain"'/g' Caddyfile
    sed -i -e 's/{MAIL}/'"$mail"'/g' Caddyfile
fi

# start caddy + v2ray
docker-compose down
docker-compose up -d

# output uuid
echo "v2ray started an $domain with new UUID : $new_uuid"
