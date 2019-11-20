#!/usr/bin/env bash

# color
red='\e[91m'
yellow='\e[93m'
none='\e[0m'

####### 参数解析 #######
cmdname=$(basename $0)
init_server=false
config_files=false

# usage help doc.
usage() {
    cat << USAGE  >&2
Usage:
    ${cmdname} [-i] [-c]
    -i          Init server, update DNS, install common utils ${install_tools[*]}, update SSH, install docker and docker-compose.
    -c          Generate  V2ray, Caddy, docker-compose config files.
    -h          Show help info.
USAGE
    exit 1
}

while getopts :ich OPT;do
    case ${OPT} in
        i)
            init_server=true
            ;;
        c)
            config_files=true
            ;;
        h)
            usage
            exit 3
            ;;
        \?)
            usage
            exit 4
            ;;
    esac
done


# Root User
[[ $(id -u) != 0 ]] && echo -e " 哎呀……请使用 ${red}root ${none}用户运行 ${yellow}~(^_^) ${none}" && exit 1

# Debian(Ubuntu) or RHEL(CentOS)
cmd="apt"
# GNU/Linux操作系统
if [[ $(command -v yum) ]]; then
    # RHEL(CentOS)
	cmd="yum"
    install_tools=(vim bind-utils net-tools mlocate wget git ufw)
else
    # Debian(Ubuntu)
    install_tools=(vim dnsutils net-tools mlocate wget git ufw)
fi

# Init Server
if [[ "${init_server}"x == "truex" ]] ; then
    # update dns before update and install
    bash <(curl -s https://raw.githubusercontent.com/yuanmomo/shell-utils/master/network/dns-util.sh)

    # both CentOS and Debian need to update
    # install common tools/utils
    ${cmd} -y update
    if [[ ${cmd} == "apt" ]]; then
        # Debian need to upgrade
        ${cmd} -y upgrade
    else
        rpm -qa | grep -qw epel-release | yum install -y epel-release
    fi

    echo "$cmd install -y ${install_tools[*]}"
    ${cmd} install -y ${install_tools[*]}

    # update ssh port and set only rsa login only
    bash <(curl -s https://raw.githubusercontent.com/yuanmomo/shell-utils/master/network/ssh-util.sh)

    # install docker and docker-compose
    bash <(curl -s -L https://git.io/JeZ5P)
fi

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

# wanip
wan_ip=`dig @resolver1.opendns.com ANY myip.opendns.com +short`

# 载入读取用户输入脚本
read_input_file="read-input.sh"
if [[ ! -e ${read_input_file} ]] ; then
    curl -s https://raw.githubusercontent.com/yuanmomo/shell-utils/master/system/read-input.sh > ${read_input_file}
fi
chmod +x ${read_input_file} && source ${read_input_file}

# backup file if file exists
function backupFile(){
    file=$1
    if [[ -e ${file} ]] ; then
        readInput " ${file} 已经存在,是否备份 (y/n)? (默认: n) " "^([y]|[n])$" "n"
        backup=${read_value}
        if [[ ${backup} == y ]]; then
            mkdir backup
            mv ${file}  backup/${file}.`date +%Y%m%d.%H%M%S`.bak
        fi
    fi
}

# temporary files
ss_config="ss-config.json"
tcp_config="tcp-config.json"
wsTlsWeb_config="wsTlsWeb-config.json"

v2ray_server_config="v2ray-server-config.json"
backupFile ${v2ray_server_config}
composeFile="docker-compose.yml"
backupFile ${composeFile}
caddyFile="Caddyfile"
backupFile ${caddyFile}

# 根据配置 生成 ${v2ray_server_config} 文件
function generateV2rayConfigFile() {
cat > ${v2ray_server_config} << EOF
{
    "stats": {},
        "api": {
            "tag": "api",
            "services": [
                "StatsService"
            ]
        },
        "policy": {
            "levels": {
                "0": {
                    "statsUserUplink": true,
                    "statsUserDownlink": true
                }
            },
            "system": {
                "statsInboundUplink": true,
                "statsInboundDownlink": true
            }
        },
        "log": {
            "access": "/var/log/v2ray/access.log",
            "error": "/var/log/v2ray/error.log",
            "loglevel": "warning"
        },
        "inbounds": [

EOF
    # 插入 shadowsocks inbound
    if [[ -e ${ss_config} ]] ; then
        cat ${ss_config} >> ${v2ray_server_config}
	fi

    # 插入 v2ray tcp inbound
    if [[ -e ${ss_config} ]] ; then
        cat ${tcp_config} >> ${v2ray_server_config}
	fi

    # 插入 v2ray WebSocket + TLS + Web inbound
    if [[ -e ${ss_config} ]] ; then
        cat ${wsTlsWeb_config} >> ${v2ray_server_config}
	fi

cat >> ${v2ray_server_config} << EOF
        {
            "listen": "127.0.0.1",
            "port": 8080,
            "protocol": "dokodemo-door",
            "settings": {
                "address": "127.0.0.1"
            },
            "tag": "api"
        }
    ],
    "outbounds": [
    {
        "protocol": "freedom",
        "settings": {},
        "tag": "direct"
    },
    {
        "protocol": "blackhole",
        "settings": {},
        "tag": "blocked"
    }
    ],
    "routing": {
        "domainStrategy": "IPOnDemand",
        "rules": [
        {
            "type": "field",
            "inboundTag": [
                "api"
            ],
            "outboundTag": "api"
        },
        {
            "type": "field",
            "protocol": [
                "bittorrent"
            ],
            "outboundTag": "blocked"
        }
        ]
    }
}
EOF
}

# 配置服务器，根据用户输入，生成配置文件
function generateServerConfigFiles() {

    # generate docker-compose.yml
cat > ${composeFile} << EOF
version: '3'
services:
  v2ray:
    restart: always
    image: v2fly/v2fly-core:latest
    container_name: v2ray
    network_mode: "host"
    volumes:
      - ./log/v2ray:/var/log/v2ray/
      - ./${v2ray_server_config}:/etc/v2ray/config.json
EOF

    # ss
    readInput "是否开启 Shadowsocks 服务, (y/n)? (默认: n) " "^([y]|[n])$" "n"
    add_ss=${read_value}
    if [[ ${add_ss} == y ]]; then
        echo "开始生成 ss 配置。。。。。"

        readInput "请指定 ss 端口号 (可用范围为0-65535, 推荐使用大端口号), 默认 39832:  ? " "^([0-9]{1,4}|[1-5][0-9]{4}|6[0-5]{2}[0-3][0-5])$" "39832"
        ss_port=${read_value}

        new_ss_pwd=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 24 | head -n 1)
cat >> ${ss_config}  << EOF
        {
            "sniffing": {
                "enabled": true,
                "destOverride": [
                    "http",
                "tls"
                ]
            },
            "port": ${ss_port},
            "protocol": "shadowsocks",
            "settings": {
                "method": "chacha20-ietf-poly1305",
                "ota": false,
                "password": "${new_ss_pwd}"
            }

        },
EOF

    fi

    # v2ray tcp
    readInput "是否开启 V2ray tcp 服务, (y/n)? (默认: n) " "^([y]|[n])$" "n"
    add_tcp=${read_value}
    if [[ ${add_tcp} == y ]]; then
        echo "开始生成 V2ray TCP 配置。。。。。"

        readInput "请指定 V2ray TCP 端口号 (可用范围为0-65535, 推荐使用大端口号), 默认 37849:  ? " "^([0-9]{1,4}|[1-5][0-9]{4}|6[0-5]{2}[0-3][0-5])$" "37849"
        tcp_port=${read_value}

        new_uuid_tcp=$(cat /proc/sys/kernel/random/uuid)
cat >> ${tcp_config}  << EOF
        {
            "sniffing": {
                "enabled": true,
                "destOverride": [
                    "http",
                "tls"
                ]
            },
            "port": ${tcp_port},
            "protocol": "vmess",
            "settings": {
                "clients": [
                {
                    "id": "${new_uuid_tcp}",
                    "level": 1,
                    "alterId": 32
                }
                ]
            }
        },

EOF
    fi

    # v2ray WebSocket + TLS + Web
    readInput "是否开启 V2ray(WebSocket + TLS + Web) 服务, (y/n)? (默认: n) " "^([y]|[n])$" "n"
    add_ws_tls_web=${read_value}
    if [[ ${add_ws_tls_web} == y ]]; then
        echo "开始生成 V2ray WebSocket + TLS + Web 配置。。。。。"

        readInput "请指定 V2ray ws 端口号 (可用范围为0-65535, 推荐使用大端口号), 默认 30000:  ? " "^([0-9]{1,4}|[1-5][0-9]{4}|6[0-5]{2}[0-3][0-5])$" "30000"
        wsPort=${read_value}

        new_uuid_ws_tls=$(cat /proc/sys/kernel/random/uuid)
cat >> ${wsTlsWeb_config}  << EOF
        {
            "sniffing": {
                "enabled": true,
                "destOverride": [
                    "http",
                "tls"
                ]
            },
            "port": ${wsPort},
            "protocol": "vmess",
            "settings": {
                "clients": [
                {
                    "id": "${new_uuid_ws_tls}",
                    "level": 1,
                    "alterId": 32
                }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/api"
                }
            }
        },
EOF

        readInput "请输入域名，配置 Caddyfile：" "^([0-9a-zA-Z\.]+)$"
        domain=${read_value}

        # CDN
        readInput "是否启动 CloudFlare CDN，需要配置 CloudFlare 邮箱和 Global API Key, (y/n)? (默认: n) " "^([y]|[n])$" "n"
        cf_on=${read_value}

        # append caddy into docker-compose.yml
cat >> ${composeFile} << EOF
  caddy:
    image: abiosoft/caddy
    container_name: caddy
    environment:
      - ACME_AGREE=true
EOF
        mail=""
        caddy_tls_config="${mail}"
        if [[ ${cf_on} == y ]]; then
            readInput "请输入 CloudFlare 邮箱: " "^([A-Za-z0-9_\-\.])+\@([A-Za-z0-9_\-\.])+\.([A-Za-z]{2,4})$"
            mail=${read_value}

            readInput "请输入 Global API Key: " "^([A-Za-z0-9]+)$"
            cfApiKey=${read_value}

            caddy_tls_config=`echo -e "{\n dns cloudflare \n }"`

            # append CloudFlare config into docker-compose.yml
cat >> ${composeFile} << EOF
      - CLOUDFLARE_EMAIL=${mail}
      - CLOUDFLARE_API_KEY=${cfApiKey}
EOF
        else
            readInput "请输入一个邮箱账号，配置 Caddyfile : " "^([A-Za-z0-9_\-\.])+\@([A-Za-z0-9_\-\.])+\.([A-Za-z]{2,4})$"
            mail=${read_value}
        fi

cat >> ${composeFile} << EOF
    network_mode: "host"
    depends_on:
      - "v2ray"
    volumes:
      - ./Caddyfile:/etc/Caddyfile
      - ./caddy/:/root/.caddy/
      - ./log/caddy:/var/log/caddy
      - ./static:/static
EOF


cat > ${caddyFile} << EOF
${domain} {
	tls ${caddy_tls_config}
	log / /var/log/caddy/access.log "{>X-Forwarded-For} -> {remote} - {user} [{when}] \"{method} {uri} {proto}\" {status} {size}" {
        rotate_size 100  # Rotate after 50 MB
        rotate_age  90  # Keep rotated files for 90 days
        rotate_keep 90  # Keep at most 20 log files
    }
	errors /var/log/caddy/error.log
	timeouts none
	root /static
    index index.html
	proxy /api 127.0.0.1:${wsPort} {
		websocket
		header_upstream -Origin
	}
}
EOF

    fi


    # generate v2ray-server-config
    generateV2rayConfigFile

    # delete temp files
    rm -f ${ss_config}
    rm -f ${tcp_config}
    rm -f ${wsTlsWeb_config}

    # echo result
    if [[ ${add_ss} == y ]]; then
        echo "SS 启动信息: "
        echo "      IP: ${wan_ip}"
        echo "      Port: ${ss_port}"
        echo "      Password: ${new_ss_pwd}"
        echo "      method: chacha20-ietf-poly1305"
        # ufw allow port
        port_allow_ufw ${ss_port} "tcp"

        echo ""
        echo ""
    fi
    
    if [[ ${add_tcp} == y ]]; then
        echo "V2ray TCP 启动信息: "
        echo "      IP: ${wan_ip}"
        echo "      Port: ${tcp_port}"
        echo "      UUID: ${new_uuid_tcp}"
        # ufw allow port
        port_allow_ufw ${tcp_port} "tcp"

        echo ""
        echo ""
    fi
    
    if [[ ${add_ws_tls_web} == y ]]; then
        echo "V2ray WebSocket + TLS + Web 启动信息: "
        echo "      Domain: ${domain}"
        echo "      Port: 443"
        echo "      IP: ${wan_ip}"
        echo "      UUID: ${new_uuid_ws_tls}"
        # ufw allow port
        port_allow_ufw 80 "tcp"
        port_allow_ufw 443 "tcp"

        echo ""
        echo ""
    fi
}


if [[ "${config_files}"x == "truex" ]] ; then
    generateServerConfigFiles
fi

# download static directory

# 创建一个与要clone的仓库同名或不同命的目录
# mkdir static && cd static
#初始化
git init
# 增加远端的仓库地址
git remote add origin  https://github.com/yuanmomo/docker-caddy-v2ray.git
# 设置Sparse Checkout 为true
git config core.sparsecheckout true
# 将要部分clone的目录相对根目录的路径写入配置文件
echo "static" >> .git/info/sparse-checkout
#pull下来代码
#git pull origin master
#只保留最新的文件而不要历史版本的文件, 浅克隆
git pull --depth 1 origin master

# start caddy + v2ray
docker-compose down
docker-compose up -d

# show iptables
echo "端口监听 ： "
netstat -anp | grep -i tcp | grep LISTEN

echo ""
echo "防火墙状态 ： "
ufw status verbose

