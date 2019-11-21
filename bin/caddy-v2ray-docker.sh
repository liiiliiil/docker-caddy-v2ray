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

###### 获取外网 IP 地址
wan_ip=`dig @resolver1.opendns.com ANY myip.opendns.com +short`

###### 判断当前用户
[[ $(id -u) != 0 ]] && echo -e " 哎呀……请使用 ${red}root ${none}用户运行 ${yellow}~(^_^) ${none}" && exit 1

####### 判断系统类型
#cmd="apt"
## GNU/Linux操作系统
#if [[ $(command -v yum) ]]; then
#    # RHEL(CentOS)
#	cmd="yum"
#fi

###### 加载工具脚本
function source_file() {
    read_input_file=$1
    if [[ -e ${read_input_file}  ]] ; then
        source ${read_input_file}
    fi
}
function printConfig(){
    tip=$1
    echo ""
    echo "
${tip}:

    VMess TCP 端口 和 UUID         : ${V2RAY_TCP_PORT} , ${V2RAY_TCP_UUID}

    Caddy + TLS + WS  端口 和 UUID : ${V2RAY_WS_PORT} , ${V2RAY_WS_UUID}

    Caddy 域名 和 邮箱              : ${DOMAIN} , ${TLS_MAIL}

    CloudFlare 账号                : ${CF_MAIL} , ${CF_API_KEY}
    "
}
function writeToConfigSh(){
    cat > ${root_dir}/${config_sh_file} << EOF
#!/usr/bin/env bash

V2RAY_TCP_PORT=${V2RAY_TCP_PORT}
V2RAY_TCP_UUID=${V2RAY_TCP_UUID}

V2RAY_WS_PORT=${V2RAY_WS_PORT}
V2RAY_WS_UUID=${V2RAY_WS_UUID}

DOMAIN=${DOMAIN}
TLS_MAIL=${TLS_MAIL}

CF_MAIL=${CF_MAIL}
CF_API_KEY=${CF_API_KEY}
EOF

}
source_file ${root_dir}/bin/read-input.sh
source_file ${root_dir}/bin/ufw-util.sh

if [[ -e ${root_dir}/${config_sh_file}  ]] ; then
    source_file ${root_dir}/${config_sh_file}
    printConfig "${config_sh_file} 文件保存的配置信息"
fi

##### 备份当前配置
source_file ${root_dir}/bin/backup-to-config.sh

###### 更新 ssh 配置
key_word="#INITIALIZED by MoMo"
if [[ ! $(grep "${key_word}" /etc/ssh/sshd_config) ]] ; then
    # update ssh port and set only rsa login only
    bash ${root_dir}/bin/ssh-util.sh
    echo "${key_word}">> /etc/ssh/sshd_config
fi
###### 安装 docker && docker-compose
if [[ ! $(command -v docker) || ! $(command -v docker-compose) ]]; then
    bash <(curl -s -L https://git.io/JeZ5P)
fi


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

    [9]: 更新 Caddy 和 V2ray 版本

请输入序号, 默认选择 [ 1 ].... " "^([123459])$" "1"
OPT_TYPE=${read_value}

echo "当前选择操作 : [${OPT_TYPE}] "
echo ""

function copyFile(){
    source=$1
    target=$2

    echo "copy ${source} 模版文件...."
    cp -fv ${source} ${target}
}

copyFile ${template_dir}/v2ray-server-config.json  ${v2ray_server_config_file}
copyFile ${template_dir}/docker-compose.yml ${compose_file}
copyFile ${template_dir}/Caddyfile ${caddy_file}

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

function replaceFile(){
    file=$1

    content=`cat ${file} | envsubst`
    cat <<< "$content" > ${file}
}
printConfig "替换配置文件中的变量"
replaceFile ${v2ray_server_config_file}
replaceFile ${compose_file}
replaceFile ${caddy_file}

echo "启动容器。。。。。"
# start caddy + v2ray
docker-compose down
docker-compose up -d
