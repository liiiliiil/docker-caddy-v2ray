#!/usr/bin/env bash

read_value=""

## 根据提示，读取用户输入
# $1 提示信息
# #2 value 的合法值的正则形式
# $3 默认值
function readInput(){
    read_value=""

    tip_msg="$1"
    value_regex="$2"
    default_value="$3"

    until  [[ $read_value =~ $value_regex ]];do
        read -p "${tip_msg}" read_value;read_value=${read_value:-$default_value}
    done
}

### shell 不能返回字符串，需要设置一个全局变量，函数里面修改全局变量的值
# read_value=""

#readInput "请输入 Port,  默认 22  :"  "^([0-9]{1,4}|[1-5][0-9]{4}|6[0-5]{2}[0-3][0-5])$" "22"
#echo " port : $read_value"
#
#readInput "请输入 api :" "^([0-9a-zA-Z]+)$"
#echo " port : $read_value"

function readPortAndUUID(){
    current_type_name="$1"
    default_port="$2"
    port_config="$3"
    uuid_config="$4"

    echo ""
    echo ""
    echo "读取 ${current_type_name} 的配置信息......."
    echo ""

    readInput "请输入 V2ray ${current_type_name} 的端口 (可用范围为0-65535, 默认 ${default_port}): [Enter] ? " "^([0-9]{1,4}|[1-5][0-9]{4}|6[0-5]{2}[0-3][0-5])$" "${default_port}"
    eval "${port_config}=${read_value}"

    if [[ $(eval echo \${${uuid_config}}) != "" ]] ; then
        echo "${current_type_name} 当前存在 UUID [$(eval echo \${${uuid_config}})], 继续使用 ！！！！"
    else
        eval "${uuid_config}=$(cat /proc/sys/kernel/random/uuid)"
        echo "${current_type_name} 生成新的 UUID [$(eval echo \${${uuid_config}})] ！！！！"
    fi
    echo "${current_type_name} 配置信息:
        PORT : [$(eval echo \${${port_config}})]
        UUID : [$(eval echo \${${uuid_config}})]
    "
    echo ""
}

function readTcpInput(){
    readPortAndUUID "VMess TCP" 37849 "V2RAY_TCP_PORT" "V2RAY_TCP_UUID"
}

function readTlsWsInput(){
    readPortAndUUID "Caddy + TLS + WS" 30000 "V2RAY_WS_PORT" "V2RAY_WS_UUID"

    readInput "请输入域名，配置 Caddyfile：" "^([0-9a-zA-Z\.]+)$"
    DOMAIN=${read_value}
}

function readMail(){
    tip=$1
    mail_config=$2

    readInput "${tip}" "^([A-Za-z0-9_\-\.])+\@([A-Za-z0-9_\-\.])+\.([A-Za-z]{2,4})$"
    eval "${mail_config}=${read_value}"

    echo "邮箱地址 :
        MAIL : [$(eval echo \${${mail_config}})]
    "
}

function readMailInput(){
    readMail "请输入一个邮箱地址，配置 HTTPS 服务:[ Caddyfile ]" "MAIL"
}

function readCloudFlareInput(){
    readMail "请输入 CloudFlare 邮箱: " "CF_MAIL"

    readInput "请输入 Global API Key: " "^([A-Za-z0-9]+)$"
    CF_API_KEY=${read_value}

    echo "CloudFlare 配置信息 :
        CF_MAIL     : [${CF_MAIL}]
        CF_API_KEY  : [${CF_API_KEY}]
    "
}

function copyFile(){
    file=$1
    source=$2
    target=$3

    echo "copy ${file} 模版文件...."
    cp -fv ${source} ${target}
}

