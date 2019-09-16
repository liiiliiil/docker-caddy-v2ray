#!/bin/bash

# 判断用户身份
if [[ "$EUID" != 0 ]]; then
    echo "请以`cat /etc/passwd |cut -d: -f1|head -1`用户运行本脚本";
    exit;
fi

install_tools=(vim mosh dnsutils ufw curl mlocate )

# 脚本说明
cat << EOF

1. 默认配置 DNS server 为 8.8.8.8 和 8.8.4.4
2. 默认安装工具 : ${install_tools[*]}
3. 修改用户密码
2. 配置 SSH 服务
    2.1 修改 sshd port
    2.2 禁用密码登陆，仅允许免密登陆
    2.3 禁用 DNS 反向解析
3. 中文化Linux
	语言地区配置（zh_CN.UTF-8）、校准时间（CST-8）
4. 配置安装 docker-caddy-v2ray
推荐使用 Debian 系统
键入回车则使用默认值
EOF


# update dns server
dns_config=/etc/resolv.conf
sed -i 's/^nameserver.*$//g' $dns_config
echo "
nameserver 8.8.8.8
nameserver 8.8.4.4
" >> $dns_config
## delete blank rows
sed -i '/^$/d' /etc/resolv.conf


# update Debian
apt update;
apt upgrade;

# install common tools
apt install -y ${install_tools[*]}


# 更改用户"$USER"密码
read -p "是否需要修改"$USER"密码（y/n）：" chmi
until [[ $chmi =~ ^([y]|[n])$ ]]; do
    read -p "请重新键入是否需要修改"$USER"密码（y/n）：" chmi
done
if [[ $chmi == y ]]; then
    echo 更改用户"$USER"密码
        passwd
    until [[ `echo $?` == "0" ]]; do
        passwd
    done
fi


# ufw firewall
## enable ufw， default incoming : deny
ufw enable
ufw default deny


# change ssh config
read -p "是否需要修改 SSH 配置（y/n）：" chsh
until [[ $chmi =~ ^([y]|[n])$ ]]; do
    read -p "请重新键入是否需要修改 SSH 配置（y/n）：" chsh
done
if [[ $chsh == y ]]; then
    read -p "请指定自定义SSH端口号（可用范围为0-65535 推荐使用大端口号）：" Port;Port=${Port:-22233}
    until  [[ $Port =~ ^([0-9]{1,4}|[1-5][0-9]{4}|6[0-5]{2}[0-3][0-5])$ ]];do
        read -p "请重新键入SSH自定义端口号：" Port;Port=${Port:-22233};
    done

    # update port
    sed -i 's/^Port/#Port/g' /etc/ssh/sshd_config
    # turn off password authentication
    sed -i 's/^PasswordAuthentication/#PasswordAuthentication/g' /etc/ssh/sshd_config
    # turn off dns
    sed -i 's/^UseDNS/#UseDNS/g' /etc/ssh/sshd_config

    echo "Port $Port">> /etc/ssh/sshd_config
    echo "PasswordAuthentication no">> /etc/ssh/sshd_config
    echo "UseDNS no">> /etc/ssh/sshd_config

    service sshd restart

    ufw allow $Port/tcp

    echo "新的 SSH 端口号 : $Port"
fi

# 中文化Linux
read -p "是否需要中文化Linux（y/n）：" chcn
until [[ $chcn =~ ^([y]|[n])$ ]]; do
    read -p "请重新键入是否需要中文化Linux（y/n）：" chcn;
done
if [[ $chcn == y ]]; then
    echo "正在更改地区、语言配置"
    apt-get install locales-all
fi

## 使用数字显示防火墙的规则
ufw status numbered

