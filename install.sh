#!/usr/bin/env bash

#######################################
# 输出警告(红色)信息
# Globals:
#
# Arguments:
#   $1. info to print
#######################################
LOG_WARN() {
    local content=${1}
    echo -e "\033[31m[WARN] ${content}\033[0m"
}

#######################################
# 输出提示（绿色）信息
# Globals:
#
# Arguments:
#   $1. info to print
#######################################
LOG_INFO() {
    local content=${1}
    echo -e "\033[32m[INFO] ${content}\033[0m"
}


LOG_INFO "配置 DNS server 为 8.8.8.8 和 8.8.4.4"
# update dns server
dns_config="/etc/resolv.conf"
sed -i 's/^nameserver.*$//g' ${dns_config}

printf "\nnameserver 8.8.8.8\nnameserver 8.8.4.4\n" >> ${dns_config}

## delete blank rows
sed -i '/^$/d' ${dns_config}


###### 需要安装的软件
install_apps=(curl git vim net-tools mlocate wget ufw gettext coreutils ufw)

# 判断系统类型
if [[ $(command -v yum) ]]; then
    # RHEL(CentOS)
    echo "install apps ${install_apps[*]} bind-utils "
    yum install -y ${install_apps[*]} bind-utils
else
    # Debian(Ubuntu)
    echo "install apps ${install_apps[*]} dnsutils "
    apt install -y ${install_apps[*]} dnsutils
fi


LOG_INFO "git clone ..."
git clone https://github.com/yuanmomo/docker-caddy-v2ray.git

bash $(pwd)/docker-caddy-v2ray/util/util.sh init

bash $(pwd)/docker-caddy-v2ray/util/util.sh deploy
