#!/usr/bin/env bash

# 默认安装的工具
#install_tools=(vim mosh dnsutils curl mlocate)
#
## 脚本说明
#red='\e[91m'
#yellow='\e[93m'
#none='\e[0m'
#
## Root User
#[[ $(id -u) != 0 ]] && echo -e " 哎呀……请使用 ${red}root ${none}用户运行 ${yellow}~(^_^) ${none}" && exit 1
#
## update dns
#curl <(curl -s https://raw.githubusercontent.com/yuanmomo/shell-utils/master/network/dns-util.sh)
#
## install common tools/utils
#curl -s https://raw.githubusercontent.com/yuanmomo/shell-utils/master/system/install-apps.sh | bash -s  ${install_tools[*]}
#
## install docker and docker-compose
#bash <(curl -s https://raw.githubusercontent.com/yuanmomo/shell-utils/master/docker/docker-docker-compose.sh)
#
## update ssh port and set only rsa login only
#bash <(curl -s https://raw.githubusercontent.com/yuanmomo/shell-utils/master/network/ssh-util.sh)

# source
wget -O read-input.sh https://raw.githubusercontent.com/yuanmomo/shell-utils/master/system/read-input.sh && chmod +x read-input.sh && ./read-input.sh

readInput "请输入 Port,  默认 22  :"  "^([0-9]{1,4}|[1-5][0-9]{4}|6[0-5]{2}[0-3][0-5])$" "22"
echo " port : $read_value"

readInput "请输入 api :" "^([0-9a-zA-Z]+)$"
echo " port : $read_value"

## temporary files
#ss_config="ss-config.json"
#tcp_config="tcp-config.json"
#wsTlsWeb_config="wsTlsWeb-config.json"
#v2ray_server_config="v2ray-server-config.json"
#composeFile="docker-compose.yml"
#caddyFile="Caddyfile"
#
## 根据配置 生成 ${v2ray_server_config} 文件
#function generateV2rayConfigFile() {
#cat > ${v2ray_server_config} << EOF
#{
#    "stats": {},
#        "api": {
#            "tag": "api",
#            "services": [
#                "StatsService"
#            ]
#        },
#        "policy": {
#            "levels": {
#                "0": {
#                    "statsUserUplink": true,
#                    "statsUserDownlink": true
#                }
#            },
#            "system": {
#                "statsInboundUplink": true,
#                "statsInboundDownlink": true
#            }
#        },
#        "log": {
#            "access": "/var/log/v2ray/access.log",
#            "error": "/var/log/v2ray/error.log",
#            "loglevel": "warning"
#        },
#        "inbounds": [
#
#EOF
#    # 插入 shadowsocks inbound
#    cat $ss_config >> ${v2ray_server_config}
#
#    # 插入 v2ray tcp inbound
#    cat $tcp_config >> ${v2ray_server_config}
#
#    # 插入 v2ray WebSocket + TLS + Web inbound
#    cat $wsTlsWeb_config >> ${v2ray_server_config}
#
#cat >> ${v2ray_server_config} << EOF
#        {
#            "listen": "127.0.0.1",
#            "port": 8080,
#            "protocol": "dokodemo-door",
#            "settings": {
#                "address": "127.0.0.1"
#            },
#            "tag": "api"
#        }
#    ],
#    "outbounds": [
#    {
#        "protocol": "freedom",
#        "settings": {},
#        "tag": "direct"
#    },
#    {
#        "protocol": "blackhole",
#        "settings": {},
#        "tag": "blocked"
#    }
#    ],
#    "routing": {
#        "domainStrategy": "IPOnDemand",
#        "rules": [
#        {
#            "type": "field",
#            "inboundTag": [
#                "api"
#            ],
#            "outboundTag": "api"
#        },
#        {
#            "type": "field",
#            "protocol": [
#                "bittorrent"
#            ],
#            "outboundTag": "blocked"
#        }
#        ]
#    }
#}
#EOF
#}
#
## 配置服务器，根据用户输入，生成配置文件
#function generateServerConfigFiles() {
#
#    # generate docker-compose.yml
#cat > $composeFile << EOF
#version: '3'
#services:
#  v2ray:
#    restart: always
#    image: v2ray/official
#    container_name: v2ray
#    network_mode: "host"
#    volumes:
#      - ./log/v2ray:/var/log/v2ray/
#      - ./${v2ray_server_config}:/etc/v2ray/config.json
#EOF
#
#    # ss
#    tip_msg="是否开启 Shadowsocks 服务（y/n）："
#    read -p "$tip_msg" addSs
#    until [[ $addSs =~ ^([y]|[n])$ ]]; do
#        read -p "$tip_msg" addSs
#    done
#    if [[ $addSs == y ]]; then
#        echo "开始生成 ss 配置。。。。。"
#        tip_msg="请指定 ss 端口号（可用范围为0-65535 推荐使用大端口号），默认 39832: "
#        read -p "$tip_msg" ssPort;ssPort=${ssPort:-39832}
#        until  [[ $ssPort =~ ^([0-9]{1,4}|[1-5][0-9]{4}|6[0-5]{2}[0-3][0-5])$ ]];do
#            read -p "$tip_msg" ssPort;ssPort=${ssPort:-39832};
#        done
#
#
#        new_ss_pwd=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 24 | head -n 1)
#cat >> $ss_config  << EOF
#        {
#            "sniffing": {
#                "enabled": true,
#                "destOverride": [
#                    "http",
#                "tls"
#                ]
#            },
#            "port": $ssPort,
#            "protocol": "shadowsocks",
#            "settings": {
#                "method": "chacha20-ietf-poly1305",
#                "ota": false,
#                "password": "$new_ss_pwd"
#            }
#
#        },
#EOF
#    fi
#
#    # v2ray tcp
#    tip_msg="是否开启 V2ray tcp 服务（y/n）："
#    read -p "$tip_msg" addTcp
#    until [[ $addTcp =~ ^([y]|[n])$ ]]; do
#        read -p "$tip_msg" addTcp
#    done
#    if [[ $addTcp == y ]]; then
#        echo "开始生成 V2ray TCP 配置。。。。。"
#        tip_msg="请指定 V2ray TCP 端口号（可用范围为0 - 65535 推荐使用大端口号），默认 37849: "
#        read -p "$tip_msg" tcpPort;tcpPort=${tcpPort:-37849}
#        until  [[ $tcpPort =~ ^([0-9]{1,4}|[1-5][0-9]{4}|6[0-5]{2}[0-3][0-5])$ ]];do
#            read -p "$tip_msg" tcpPort;tcpPort=${tcpPort:-37849};
#        done
#
#        new_uuid_tcp=$(cat /proc/sys/kernel/random/uuid)
#cat >> $tcp_config  << EOF
#        {
#            "sniffing": {
#                "enabled": true,
#                "destOverride": [
#                    "http",
#                "tls"
#                ]
#            },
#            "port": $tcpPort,
#            "protocol": "vmess",
#            "settings": {
#                "clients": [
#                {
#                    "id": "$new_uuid_tcp",
#                    "level": 1,
#                    "alterId": 32
#                }
#                ]
#            }
#        },
#
#EOF
#    fi
#
#    # v2ray WebSocket + TLS + Web
#    tip_msg="是否开启 V2ray(WebSocket + TLS + Web) 服务（y/n）："
#    read -p "$tip_msg" addWsTlsWeb
#    until [[ $addWsTlsWeb =~ ^([y]|[n])$ ]]; do
#        read -p "$tip_msg" addWsTlsWeb
#    done
#    if [[ $addWsTlsWeb == y ]]; then
#        echo "开始生成 V2ray WebSocket + TLS + Web 配置。。。。。"
#
#        tip_msg="请指定 V2ray ws 端口号（可用范围为0 - 65535 推荐使用大端口号），默认 30000: "
#        read -p "$tip_msg" wsPort;wsPort=${wsPort:-30000}
#        until  [[ $wsPort =~ ^([0-9]{1,4}|[1-5][0-9]{4}|6[0-5]{2}[0-3][0-5])$ ]];do
#            read -p "$tip_msg" wsPort;wsPort=${wsPort:-30000};
#        done
#
#        new_uuid_ws_tls=$(cat /proc/sys/kernel/random/uuid)
#cat >> $wsTlsWeb_config  << EOF
#        {
#            "sniffing": {
#                "enabled": true,
#                "destOverride": [
#                    "http",
#                "tls"
#                ]
#            },
#            "port": $wsPort,
#            "protocol": "vmess",
#            "settings": {
#                "clients": [
#                {
#                    "id": "$new_uuid_ws_tls",
#                    "level": 1,
#                    "alterId": 32
#                }
#                ]
#            },
#            "streamSettings": {
#                "network": "ws",
#                "wsSettings": {
#                    "path": "/"
#                }
#            }
#        },
#EOF
#
#        tip_msg="请输入 域名，配置 Caddyfile："
#        read -p "$tip_msg" domain;
#        until [[ $domain ]]; do
#            read -p "$tip_msg" domain;
#        done
#
#        # CDN
#        tip_msg="是否启动 CloudFlare CDN，需要配置 CloudFlare 邮箱和 Global API Key（y/n）："
#        read -p "$tip_msg" cfOn;
#        until [[ $addWsTlsWeb =~ ^([y]|[n])$ ]]; do
#            read -p "$tip_msg" cfOn;
#        done
#
#        # append caddy into docker-compose.yml
#
#cat >> $composeFile << EOF
#  caddy:
#    image: abiosoft/caddy
#    container_name: caddy
#    environment:
#      - ACME_AGREE=true
#EOF
#
#        mail=""
#        caddy_tls_config="$mail"
#        if [[ $cfOn == y ]]; then
#            tip_msg="请输入 CloudFlare 邮箱："
#            read -p "$tip_msg" mail;
#            until [[ $mail ]]; do
#                read -p "$tip_msg" mail;
#            done
#
#            tip_msg="请输入 Global API Key 邮箱："
#            read -p "$tip_msg" cfApiKey;
#            until [[ $cfApiKey ]]; do
#                read -p "$tip_msg" cfApiKey;
#            done
#
#            caddy_tls_config=`echo -e "{\n dns cloudflare \n }"`
#
#cat >> $composeFile << EOF
#      - CLOUDFLARE_EMAIL=$mail
#      - CLOUDFLARE_API_KEY=$cfApiKey
#EOF
#        else
#            tip_msg="请输入一个邮箱账号，配置 Caddyfile："
#            read -p "$tip_msg" mail;
#            until [[ ! $mail ]]; do
#                read -p "$tip_msg" mail;
#            done
#        fi
#
#
#cat >> $composeFile << EOF
#    network_mode: "host"
#    depends_on:
#      - "v2ray"
#    volumes:
#      - ./Caddyfile:/etc/Caddyfile
#      - ./caddy/:/root/.caddy/
#      - ./log/caddy:/var/log/caddy
#EOF
#
#
#cat > $caddyFile << EOF
#$domain {
#	tls $caddy_tls_config
#	log /var/log/caddy/access.log
#	errors /var/log/caddy/error.log
#	timeouts none
#	proxy / v2ray:$wsPort {
#		websocket
#	}
#}
#EOF
#
#    fi
#
#
#    # generate v2ray-server-config
#    generateV2rayConfigFile
#
#    rm -f $ss_config
#    rm -f $tcp_config
#    rm -f $wsTlsWeb_config
#
#}
#
#
#generateServerConfigFiles
#
#
#
## show iptables
##iptables --list | grep ACCEPT | grep tcp
#
#
