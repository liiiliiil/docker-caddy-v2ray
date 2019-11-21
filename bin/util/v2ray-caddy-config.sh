#!/usr/bin/env bash

###### 配置常量
red='\e[91m'
yellow='\e[93m'
none='\e[0m'

root_dir="$(cd "$(dirname "$0")";pwd)/.."
template_dir="${root_dir}/template"
back_up_dir="${root_dir}/backup"

v2ray_server_config_file="${root_dir}/v2ray-server-config.json"
compose_file="${root_dir}/docker-compose.yml"
caddy_file="${root_dir}/Caddyfile"

config_sh_file="config.sh"

modify=$1

###### 获取外网 IP 地址
wan_ip=`dig @resolver1.opendns.com ANY myip.opendns.com +short`

###### 判断当前用户
[[ $(id -u) != 0 ]] && echo -e " 哎呀……请使用 ${red}root ${none}用户运行 ${yellow}~(^_^) ${none}" && exit 1

# source files
source ${root_dir}/bin/source/common_function.sh
source_file ${root_dir}/bin/source/read-input.sh
source_file ${root_dir}/bin/source/ufw.sh
if [[ -e ${root_dir}/${config_sh_file}  ]] ; then
    source_file ${root_dir}/${config_sh_file}
    printConfig "${config_sh_file} 文件保存的配置信息"
fi

##### 备份当前配置
source_file ${root_dir}/bin/source/backup-config.sh

####### 定义变量，读取用户的输入，根据用户的输入生成配置
# 当前操作类型
OPT_TYPE=1
# 默认启用 Caddy 的 CloudFlare 配置
CADDY_TLS_CONFIG=`echo -e "{\n dns cloudflare \n }"`

###### 读取用户配置
readInput "

欢迎使用自动脚本配置 V2ray 服务，请选择何种 [部署方式] 或者 [更新] :

    [1]: VMess 默认 TCP (默认安装方式)

    [2]: Caddy + TLS + WS

    [3]: CloudFlare(CDN) + Caddy + TLS + WS

    [4]: [VMess 默认 TCP] + [ Caddy + TLS + WS ] 两种方式

    [5]: [VMess 默认 TCP] + [ CloudFlare(CDN) + Caddy + TLS + WS ] 两种方式

请输入序号, 默认选择 [ 1 ].... " "^([12345])$" "1"
OPT_TYPE=${read_value}

echo "当前选择操作 : [${OPT_TYPE}] "
echo ""


echo "copy ${source} 模版文件...."
copyFile ${template_dir}/v2ray-server-config.json  ${v2ray_server_config_file}
copyFile ${template_dir}/docker-compose.yml ${compose_file}
copyFile ${template_dir}/Caddyfile ${caddy_file}

if [[ "${modify}" == "modify" ]] ; then
    reConfig ${OPT_TYPE}
fi

case ${OPT_TYPE} in
 1)
    # VMess TCP
    readTcpInput

    # delete tls + ws config
    sed -i '/^.*V2RAY_TLS_WS_CONFIG_START.*$/,/^.*V2RAY_TLS_WS_CONFIG_END.*$/d' ${v2ray_server_config_file}

    # delete caddy in docker-compose file
    sed -i '/^ *caddy:$/,$d' ${compose_file}

    ;;
 2)
    # Caddy + TLS + WS
    readTlsWsInput
    readMailInput
    sed '/^.*V2RAY_TCP_CONFIG_START.*$/,/^.*V2RAY_TCP_CONFIG_END.*$/d' ${v2ray_server_config_file}

    CADDY_TLS_CONFIG="${TLS_MAIL}"

    ;;
 3)
    # 配置 CloudFlare(CDN) + Caddy + TLS + WS
    readTlsWsInput
    readCloudFlareInput

    sed '/^.*V2RAY_TCP_CONFIG_START.*$/,/^.*V2RAY_TCP_CONFIG_END.*$/d' ${v2ray_server_config_file}

    ;;
 4)
    # VMess TCP
    readTcpInput

    # Caddy + TLS + WS
    readTlsWsInput
    readMailInput

    CADDY_TLS_CONFIG="${TLS_MAIL}"
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
export TLS_MAIL

export CF_MAIL
export CF_API_KEY
export CADDY_TLS_CONFIG

# 保存配置
writeToConfigSh

printConfig "替换配置文件中的变量"
replaceFile ${v2ray_server_config_file}
replaceFile ${compose_file}
replaceFile ${caddy_file}

echo "V2Ray 配置信息:

    VMess TCP  : ${V2RAY_TCP_UUID} @ ${wan_ip} : ${V2RAY_TCP_PORT} ,

    TLS + WS   : ${V2RAY_WS_UUID} @ ${DOMAIN}:443 /api:
"
