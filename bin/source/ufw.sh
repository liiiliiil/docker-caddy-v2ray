#!/usr/bin/env bash


function enable_ufw(){
    echo "开启防火墙"
    ufw --force enable
    ufw default deny
    ssh_port=`ss -tulpn | grep -i sshd | awk -F ' ' '{print $5}'  | grep "\*"|awk -F ':' '{print $2}'`

    echo "防火墙 开放 ssh 端口: [${ssh_port}] "
    ufw allow ${ssh_port}/tcp
}

# allow port and protocol
function port_allow_ufw(){
    # port
    port=$1
    # tcp or udp
    type=$2
    if [[ ! ${port} ]]; then
        echo "端口参数为空，不能开启"
        return
    fi

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
fi

#开启防火墙
enable_ufw

