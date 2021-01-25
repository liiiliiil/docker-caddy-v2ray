#!/usr/bin/env bash


#######################################
# 用环境变量的值替换文件中的占位符
# Globals:
#   all env variables
# Arguments:
#   $1. target file
#######################################
function replace_vars_in_file(){
    tpl_file="$1"
    generated_file="$2"

    install -Dv /dev/null $${my_empty_variable}{generated_file}

    content=$${my_empty_variable}(cat "$${my_empty_variable}{tpl_file}" | envsubst)
    cat <<< "$${my_empty_variable}{content}" > "$${my_empty_variable}{generated_file}"
}

cd ${deploy_root}
SUB_DOMAIN=${DOMAIN}

# get domain cert absolute path
export DOMIAN_HOST_CRT=$(readlink -f ${deploy_root}/certs/domain/live/$${my_empty_variable}{SUB_DOMAIN}/fullchain.pem)
export DOMIAN_HOST_KEY=$(readlink -f ${deploy_root}/certs/domain/live/$${my_empty_variable}{SUB_DOMAIN}/privkey.pem)


replace_vars_in_file "${deploy_root}/docker-compose-generated.yml.tpl" "${deploy_root}/docker-compose.yml"


####### 参数解析 #######
cmdname=$${my_empty_variable}(basename $${my_empty_variable}0)

# 操作参数
OPT=$${my_empty_variable}1

# usage help doc.
usage() {
    cat << USAGE  >&2

Usage:

    $${my_empty_variable}cmdname [ start[s] | stop[p] | restart[r] | help[h] ]

    [s] start    启动 Xray
    [p] stop     关闭 Xray
    [r] restart  重启 Xray
    [h] help     帮助文档

USAGE
exit 1
}

case $${my_empty_variable}OPT in
    s | start)
        docker-compose down; docker-compose up -d;
        ;;
    p | stop)
        docker-compose down
        ;;
    r | restart)
        docker-compose down; docker-compose up -d;
        ;;
    h | help )
        usage
        exit 1
        ;;
    \?)
        usage
        exit 1
        ;;
    *)
        usage
        exit 1
        ;;
esac

