#!/usr/bin/env bash

###### 配置常量
red='\e[91m'
yellow='\e[93m'
none='\e[0m'
current_dir=$(cd "$(dirname "$0")";pwd)

root_dir="${current_dir}/../"
template_dir="${root_dir}/template"
v2ray_server_config="v2ray-server-config.json"
composeFile="docker-compose.yml"
caddyFile="Caddyfile"

###### 判断当前用户
[[ $(id -u) != 0 ]] && echo -e " 哎呀……请使用 ${red}root ${none}用户运行 ${yellow}~(^_^) ${none}" && exit 1

###### 加载工具脚本
function source_file() {
    read_input_file=$1
    if [[ -e ${read_input_file}  ]] ; then
        chmod +x ${read_input_file} && source ${read_input_file}
    fi
}
source_file ${current_dir}/read-input.sh
source_file ${current_dir}/ufw-util.sh
source_file ${current_dir}/../config.sh

##### 备份当前配置
bash ${current_dir}/backup-to-config.sh

###### 判断系统类型
cmd="apt"
# GNU/Linux操作系统
if [[ $(command -v yum) ]]; then
    # RHEL(CentOS)
	cmd="yum"
fi

###### 更新 ssh 配置
key_word="#INITIALIZED by MoMo"
if [[ ! $(grep "${key_word}"  /etc/ssh/sshd_config) ]] ; then
    # update ssh port and set only rsa login only
    bash ${current_dir}/ssh-util.sh
    echo "${key_word}">> /etc/ssh/sshd_config
fi
###### 安装 docker && docker-compose
if [[ ! $(command -v docker) || ! $(command -v docker-compose) ]]; then
    bash <(curl -s -L https://git.io/JeZ5P)
fi

###### 获取外网 IP 地址
wan_ip=`dig @resolver1.opendns.com ANY myip.opendns.com +short`

####### 定义变量，读取用户的输入，根据用户的输入生成配置
# 当前操作类型
OPT_TYPE=1
# 默认启用 CloudFlare
CADDY_TLS_CONFIG=`echo -e "{\n dns cloudflare \n }"`


###### 读取用户配置
readInput "
欢迎使用自动脚本配置 V2ray 服务，请选择何种 [部署方式] 或者 [更新服务] :

[1]: VMess 默认 TCP (默认安装方式)

[2]: Caddy + TLS + WS

[3]: CloudFlare(CDN) + Caddy + TLS + WS

[4]: [VMess 默认 TCP] + [ Caddy + TLS + WS ] 两种方式

[5]: [VMess 默认 TCP] + [ CloudFlare(CDN) + Caddy + TLS + WS ] 两种方式

[9]: 更新 Caddy 和 V2ray 版本

请输入序号, 默认选择 [ 1 ].... " "^([123459])$" "1"
OPT_TYPE=${read_value}

echo "当前选择: [${OPT_TYPE}] "
echo ""

copyFile ${v2ray_server_config} ${template_dir}/${v2ray_server_config} ${root_dir}/${v2ray_server_config}
copyFile ${composeFile} ${template_dir}/${composeFile} ${root_dir}/${composeFile}
copyFile ${caddyFile} ${template_dir}/${caddyFile} ${root_dir}/${caddyFile}

case ${OPT_TYPE} in
 1)
    # VMess TCP
    readTcpInput

    # delete tls + ws config
    sed '/^.*V2RAY_TLS_WS_CONFIG_START.*$/,/^.*V2RAY_TLS_WS_CONFIG_END.*$/d' ${v2ray_server_config}

    # delete caddy in docker-compose file
    sed '/^ *caddy:$/,$d' ${composeFile}

    ;;
 2)
    # Caddy + TLS + WS
    readTlsWsInput
    readMailInput
    sed '/^.*V2RAY_TCP_CONFIG_START.*$/,/^.*V2RAY_TCP_CONFIG_END.*$/d' ${v2ray_server_config}

    CADDY_TLS_CONFIG="${MAIL}"

    ;;
 3)
    # 配置 CloudFlare(CDN) + Caddy + TLS + WS
    readTlsWsInput
    readCloudFlareInput

    sed '/^.*V2RAY_TCP_CONFIG_START.*$/,/^.*V2RAY_TCP_CONFIG_END.*$/d' ${v2ray_server_config}

    ;;
 4)
    # VMess TCP
    readTcpInput

    # Caddy + TLS + WS
    readTlsWsInput
    readMailInput

    CADDY_TLS_CONFIG="${MAIL}"
    ;;
 5)
    # VMess TCP
    readTcpInput

    # 配置 CloudFlare(CDN) + Caddy + TLS + WS
    readTlsWsInput
    readCloudFlareInput

    ;;
 *)
    echo "Unknown operation type : [${OPT_TYPE}]"
    exit 1
esac

export V2RAY_TCP_PORT
export V2RAY_TCP_UUID

export V2RAY_WS_PORT
export V2RAY_WS_UUID
export DOMAIN
export MAIL

export CF_MAIL
export CF_API_KEY
export CADDY_TLS_CONFIG



content=`cat ${root_dir}/${v2ray_server_config} | envsubst`
echo "$content"
echo ${content} > ${v2ray_server_config}

content=`cat ${root_dir}/${composeFile} | envsubst`
echo "$content"
echo ${content} > ${composeFile}

content=`cat ${root_dir}/${caddyFile} | envsubst`
echo "$content"
echo ${content} > ${caddyFile}
