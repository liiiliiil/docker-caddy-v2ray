#!/usr/bin/env bash

# backup current config
if [[ ! -d "${back_up_dir}" ]] ; then
    echo "创建 ${back_up_dir} 目录"
    mkdir ${back_up_dir}
fi

if [[ -e "${config_sh_file}" ]] ; then
    ## TODO. 判断最新的两个文件的 MD5
    backup_config_key="${back_up_dir}/config.sh.`date "+%Y%m%d-%H%M%S"`"
    echo "已经存在 ${config_sh_file} 文件，备份到 ${back_up_dir} 目录中: cp ${config_sh_file} to ${backup_config_key}"
    cp -vf ${config_sh_file} ${backup_config_key}
    
     # 如果文件存在，备份一份，然后直接返回
    return 
fi

echo ""
echo "当前不存在 ${config_sh_file} 文件, 根据当前运行的配置文件生成........"

if [[ -e "${v2ray_server_config_file}" ]] ; then
    V2RAY_TCP_PORT=`grep -A 5 -B 5 -m 1 "vmess" ${v2ray_server_config_file} | grep "port" | tr -d -c "[0-9]"`
    V2RAY_TCP_UUID=`grep -A 5 -B 5 -m 1 "vmess" ${v2ray_server_config_file} | grep "id" | awk -F ':' '{print $2}'| tr -d -c "[A-Za-z0-9\-]"`

    V2RAY_WS_PORT=`grep -B 15 "wsSettings"  ${v2ray_server_config_file}| grep "port" | tr -d -c "[0-9]"`
    V2RAY_WS_UUID=`grep -B 15 "wsSettings" ${v2ray_server_config_file} | grep "id" | awk -F ':' '{print $2}'| tr -d -c "[A-Za-z0-9\-]"`
fi

if [[ -e "${compose_file}" ]] ; then
    CF_MAIL=`grep "CLOUDFLARE_EMAIL" ${compose_file} | awk -F '=' '{print $2}'`
    CF_API_KEY=`grep "CLOUDFLARE_API_KEY" ${compose_file} | awk -F '=' '{print $2}'`
fi

if [[ -e "${caddy_file}" ]] ; then
    DOMAIN=`head -n 1 ${caddy_file} |awk '{print $1}'`
fi

writeToConfigSh

