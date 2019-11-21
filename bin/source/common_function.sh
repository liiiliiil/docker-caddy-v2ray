#!/usr/bin/env bash

###### 加载工具脚本
function source_file() {
    file_to_source=$1
    if [[ -e ${file_to_source}  ]] ; then
        source ${file_to_source}
    fi
}

function printConfig(){
    tips=$1
    echo ""
    echo "
${tips}:

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
    cat <<< "${content}" > ${file}
}

function checkDockerCompose(){
    tips=$1
    if [[ ! -e ${root_dir}/docker-compose.yml ]] ; then
        echo ${tips}
        exit 2
    fi
}

function docker_start(){
    echo "启动容器。。。。。"
    # check files
    checkDockerCompose "不存在 docker-compose.yml 文件，启动失败"

    # start caddy + v2ray
    count=`docker-compose ps | egrep -i "caddy|v2ray" |wc -l`
    if [[ ${count} > 2 ]] ; then
        # has containers
        docker-compose down
    fi
    docker-compose up -d

    echo "配置防火墙:"
    if [[ "${V2RAY_TCP_PORT}" ]] ; then
        port_allow_ufw ${V2RAY_TCP_PORT} "tcp"
    fi
    if [[ "${V2RAY_WS_PORT}" ]] ; then
        port_allow_ufw 80 "tcp"
        port_allow_ufw 443 "tcp"
    fi
    echo "当前防火墙状态:"
    ufw status verbose
}

function docker_stop(){
    echo "关闭容器。。。。。"
    checkDockerCompose "不存在 docker-compose.yml 文件，关闭失败"
    docker-compose down
}

function docker_restart(){
    echo "重启容器。。。。。"
    # start caddy + v2ray
    docker_stop
    docker_start
}

function docker_update(){
    echo "更新容器。。。。。"
    checkDockerCompose "不存在 docker-compose.yml 文件，更新失败"
    docker-compose pull caddy
}
