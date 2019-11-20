#!/usr/bin/env bash


function enable_ufw(){
    ufw --force enable
    ufw default deny
}

# allow port and protocol
function port_allow_ufw(){
    # port
    port=$1
    # tcp or udp
    type=$2

    if [[ ! ${type} ]]; then
        type="tcp"
    fi

    echo "Allow port ${port}/${type} in...."

    exist_tcp_and_udp=$(ufw status verbose |awk -F ' ' '{print $1}' |egrep -w "^${port}$")
    if [[ ${exist_tcp_and_udp} ]]; then
        # already exists
        exist_rule=`ufw status verbose | egrep -w "^${port}"`
        echo "Rule already exist : ${exist_rule} "
        return
    fi

    exist_type=$(ufw status verbose |awk -F ' ' '{print $1}' |egrep -w "^${port}/${type}$")
    if [[ ${exist_type} ]]; then
        # already exists
        exist_rule=`ufw status verbose | egrep -w "^${port}/${type}"`
        echo "Rule already exist : ${exist_rule} "
        return
    fi

    ufw allow ${port}/${type}
}

# install ufw and config
if [[ ! $(command -v ufw) ]]; then
    # install ufw
    ${cmd} install -y ufw
    enable_ufw
fi
