#!/usr/bin/env bash

# backup current config
if [[ ! -d "${back_up_dir}" ]] ; then
    echo "创建 ${back_up_dir} 目录"
    mkdir ${back_up_dir}
fi

if [[ -e "${root_dir}/${config_sh_file}" ]] ; then
    ## 如果 root 目录中的 config.sh 和 backup 中的 config.sh.xxxxx md5 相同，则不需要再备份
    current_md5=`md5sum ${root_dir}/${config_sh_file}`
    latest_backup_md5=`md5sum $(ls -t ${back_up_dir} | head -n 1) | cut -f 1 -d " "`
    if [[ "${current_md5}"x == "${latest_backup_md5}"x ]] ; then
        echo "备份已经是最新文件，不用备份"
        return
    fi

    backup_config_sh="${back_up_dir}/${config_sh_file}.`date "+%Y%m%d-%H%M%S"`"
    echo "已经存在 ${root_dir}/${config_sh_file} 文件，备份到 ${back_up_dir}  "
    cp -vf ${root_dir}/${config_sh_file} ${backup_config_sh}
    
     # 如果文件存在，备份一份，然后直接返回
    return 
fi

echo ""
echo "当前不存在 ${root_dir}/${config_sh_file} 文件, 根据当前运行的配置文件生成........"

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


printConfig "当前运行配置文件中读取到的配置信息, 写入到 ${config_sh_file} 文件"
writeToConfigSh

