#!/usr/bin/env bash

# backup current config
current_dir=$(cd "$(dirname "$0")";pwd)

config_key="config.sh"
back_up="backup"
v2ray_config_file="v2ray-server-config.json"
docker_compose_file="docker-compose.yml"
caddy_file="Caddyfile"

if [[ ! -d "${current_dir}/../${back_up}" ]] ; then
    echo "创建 ${back_up} 目录"
    mkdir ${current_dir}/../${back_up}
fi

if [[ -e "${current_dir}/../${config_key}" ]] ; then
    ## TODO. 判断最新的两个文件的 MD5
    backup_config_key="${config_key}.`date "+%Y%m%d-%H%M%S"`"
    echo "已经存在 ${config_key} 文件，备份到 ${back_up} 目录中: mv ${config_key} to ${back_up}/${backup_config_key}"
    mv -vf ${current_dir}/../${config_key} ${current_dir}/../${back_up}/${backup_config_key}
fi

echo ""
echo "生成当前的配置到 ${config_key} 文件"

if [[ -e "${current_dir}/../${v2ray_config_file}" ]] ; then
    V2RAY_TCP_PORT=`grep -A 5 -B 5 -m 1 "vmess" ${v2ray_config_file} | grep "port" | tr -d -c "[0-9]"`
    V2RAY_TCP_UUID=`grep -A 5 -B 5 -m 1 "vmess" ${v2ray_config_file} | grep "id" | awk -F ':' '{print $2}'| tr -d -c "[A-Za-z0-9\-]"`

    V2RAY_WS_PORT=`grep -B 15 "wsSettings"  ${v2ray_config_file}| grep "port" | tr -d -c "[0-9]"`
    V2RAY_WS_UUID=`grep -B 15 "wsSettings" ${v2ray_config_file} | grep "id" | awk -F ':' '{print $2}'| tr -d -c "[A-Za-z0-9\-]"`
fi

if [[ -e "${current_dir}/../${docker_compose_file}" ]] ; then
    CF_MAIL=`grep "CLOUDFLARE_EMAIL" ${docker_compose_file} | awk -F '=' '{print $2}'`
    CF_API_KEY=`grep "CLOUDFLARE_API_KEY" ${docker_compose_file} | awk -F '=' '{print $2}'`
fi

if [[ -e "${current_dir}/../${caddy_file}" ]] ; then
    DOMAIN=`head -n 1 ${caddy_file} |awk '{print $1}'`
fi

cat >> ${current_dir}/../${config_key} << EOF
#!/usr/bin/env bash

V2RAY_TCP_PORT=${V2RAY_TCP_PORT}
V2RAY_TCP_UUID=${V2RAY_TCP_UUID}

V2RAY_WS_PORT=${V2RAY_WS_PORT}
V2RAY_WS_UUID=${V2RAY_WS_UUID}
CF_MAIL=${CF_MAIL}
CF_API_KEY=${CF_API_KEY}
DOMAIN=${DOMAIN}
EOF
