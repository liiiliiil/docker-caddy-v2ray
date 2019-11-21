#!/usr/bin/env bash

###### 加载工具脚本
function source_file() {
    file_to_source=$1
    if [[ -e ${file_to_source}  ]] ; then
        source ${file_to_source}
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

function copyFile(){
    source=$1
    target=$2

    echo ""
    cp -fv ${source} ${target}
    echo ""
}



function replaceFile(){
    file=$1

    content=`cat ${file} | envsubst`
    cat <<< "$content" > ${file}
}


function docker_start(){
    echo "启动容器。。。。。"
    # start caddy + v2ray
    docker-compose down
    docker-compose up -d

    echo "配置防火墙:"
    if [[ ! "${V2RAY_TCP_PORT}" ]] ; then
        port_allow_ufw ${V2RAY_TCP_PORT} "tcp"
    fi
    if [[ ! "${V2RAY_WS_PORT}" ]] ; then
        port_allow_ufw 80 "tcp"
        port_allow_ufw 443 "tcp"
    fi
    echo "当前防火墙状态:"
    ufw status verbose
}

function docker_stop(){
    echo "关闭容器。。。。。"
    docker-compose down
}

function docker_restart(){
    echo "重启容器。。。。。"
    # start caddy + v2ray
    docker_stop
    docker_start
}

function docker_update(){
    echo "重启容器。。。。。"
    docker-compose pull caddy
}
