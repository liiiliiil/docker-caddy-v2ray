#!/usr/bin/env bash

root_dir="$(cd "$(dirname "$0")";pwd)/.."

###### 更新 DNS
echo "更新 DNS 信息"
sed -i 's/^nameserver.*$//g' /etc/resolv.conf \
    && echo "nameserver 8.8.8.8\nnameserver 8.8.4.4\n" >> /etc/resolv.conf \
    && sed -i '/^$/d' /etc/resolv.conf \

###### 需要安装的软件
install_apps=(curl git vim net-tools mlocate wget ufw gettext coreutils)
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

###### 更新 ssh 配置
key_word="#INITIALIZED by MoMo"
if [[ ! $(grep "${key_word}" /etc/ssh/sshd_config) ]] ; then
    # update ssh port and set only rsa login only
    bash ${root_dir}/bin/util/ssh-config.sh
    echo "${key_word}">> /etc/ssh/sshd_config
fi

###### 安装 docker && docker-compose
if [[ ! $(command -v docker) || ! $(command -v docker-compose) ]]; then
    bash <(curl -s -L https://git.io/JeZ5P)
fi

echo "git clone 仓库......"
git clone https://github.com/yuanmomo/docker-caddy-v2ray.git \
    && cp -fv docker-caddy-v2ray/bin/v2ray.sh /usr/local/bin \
    && chmod +x /usr/local/bin/v2ray.sh

# 执行命令
./v2ray.sh

