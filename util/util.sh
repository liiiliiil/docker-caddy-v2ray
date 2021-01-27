#!/usr/bin/env bash

#######################################
# 输出警告(红色)信息
# Globals:
#
# Arguments:
#   $1. info to print
#######################################
LOG_WARN() {
    local content=${1}
    echo -e "\033[31m[WARN] ${content}\033[0m"
}

#######################################
# 输出提示（绿色）信息
# Globals:
#
# Arguments:
#   $1. info to print
#######################################
LOG_INFO() {
    local content=${1}
    echo -e "\033[32m[INFO] ${content}\033[0m"
}

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

    install -Dv /dev/null ${generated_file}

    content=$(cat "${tpl_file}" | envsubst)
    cat <<< "${content}" > "${generated_file}"
}

#######################################
# 获取用户输入
# Globals:
#    read_value
# Arguments:
#   $1 提示信息
#   $2 使用正则校验用户的输入
#   $3 默认值
#######################################
read_value=""
function read_input(){
    read_value=""

    tip_msg="$1"
    regex_of_value="$2"
    default_value="$3"

    echo ""
    until  [[ ${read_value} =~ ${regex_of_value} ]];do
        read -r -p "${tip_msg}" read_value;read_value=${read_value:-${default_value}}
    done
}

#######################################
# 安装依赖服务

# Globals:
#
# Arguments:
#   $1 服务命令，通过检测命令是否存在来判断是否需要安装该服务
#   $2 服务名
#######################################
function install_app(){
    # 系统命令
    command=$1
    # 安装的应用名，如果系统命令不存在，则安装
    app_name=$2

    # install app
    if [[ ! $(command -v "${command}") ]] ;then
        if [[ $(command -v apt) ]]; then
            # Debian/Ubuntu
            LOG_INFO "Start to check and install ${app_name} on remote Debian system."
            sudo dpkg -l | grep -qw "${app_name}" || sudo apt install -y "${app_name}"
        elif [[ $(command -v yum) ]]; then
            ## RHEL/CentOS
            LOG_INFO "Start to check and install ${app_name} on remote RHEL system."
            sudo rpm -qa | grep -qw "${app_name}" || sudo yum install -y "${app_name}"
        fi
    else
        LOG_INFO "[${app_name}] already installed."
    fi
}


#######################################
# 在 CentOS 中禁用 SELinux
#
# Globals:
#
# Arguments:
#
#######################################
## disable SELinux on CentOS
function disable_selinux(){
    if [[ $(command -v setenforce) ]]; then
        LOG_INFO "Disabled SELinux temporarily."
        setenforce Permissive || :
    fi
}

#######################################
# 启动 Docker 服务
#
# Globals:
#
# Arguments:
#
#######################################
## start docker
function start_docker(){
    LOG_INFO "Try to start Docker service."
    disable_selinux
    systemctl start docker
}

#######################################
# 检查 Docker 是否安装成功
#
# Globals:
#
# Arguments:
#
#######################################
function check_docker(){
    # start docker
    start_docker

    LOG_INFO "Check Docker is ready to run containers."

    if [[ "$(docker run --rm hello-world | grep 'Hello from Docker!')x" != "Hello from Docker!x" ]]; then
        LOG_WARN "Install docker failed !! Please install docker manually with reference:  https://docs.docker.com/engine/install/ "
        exit 5;
    fi
}

#######################################
# 安装 Docker 服务
#
# Globals:
#
# Arguments:
#
#######################################
function install_docker(){
    LOG_INFO "Install Docker."

    if [[ ! $(command -v docker) ]]; then
        if [[ $(command -v yum) ]]; then
            ## install containerd.io if on CentOS(RHEL) 8
            # freedesktop.org and systemd
            [[ -f /etc/os-release ]] &&  source /etc/os-release

            container_io_pkg_version="1.3.9-3.1.el7"
            container_io_pkg_name="containerd.io-${container_io_pkg_version}.x86_64.rpm"
            if [[ ${VERSION_ID} -gt 7 ]] && [[ "$(yum list installed | grep -i \"${container_io_pkg_name}\" |grep -i \"${container_io_pkg_version}\")"  == "" ]]; then
                LOG_INFO "On CentOS/RHEL 8.x, install [${container_io_pkg_name}] automatically."
                yum -y install "https://download.docker.com/linux/centos/7/x86_64/stable/Packages/${container_io_pkg_name}"
            fi
        fi

        LOG_INFO "Installing Docker."
        curl -fsSL https://get.docker.com | bash ;
    else
        LOG_INFO "Docker is already installed."
    fi
}


#######################################
# 安装 Docker Compose服务
#
# Globals:
#
# Arguments:
#
#######################################
function install_docker_compose(){
    if [[ ! $(command -v docker-compose) ]]; then
        LOG_INFO "Install docker-compose 。。。。。"
        curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    else
        LOG_INFO "Docker Compose already installed!!"
    fi
}

#######################################
# 检查服务是否已经安装
#
# Globals:
#
# Arguments:
#   $1 第一个服务
#   .
#   $n 第 n 个服务
#
#######################################
function check_commands(){
    for i in "$@"; do
        if [[ ! $(command -v "$i") ]]; then
            LOG_WARN "[$i] not found, please install [$i]."
            exit 5
        fi
    done
}

#######################################
# 检查是否存在目录（是否已经部署过服务）
#
# Globals:
#
# Arguments:
#   $1 父目录
#   $2 子目录
#
#######################################
function check_directory_exists(){
    parent="$1"
    directory="$2"

    if [[ -d "${parent}/${directory}" ]]; then
        LOG_WARN "Directory:[${parent}/${directory}] exists, BACKUP:[b] or DELETE:[d]?"
        # 调用 readValue
        # 大小写转换
        read_input "BACKUP(b), DELETE(d)? [b/d], 默认: b ? " "^([Bb]|[Dd])$" "b"
        delete_directory=$(echo "${read_value}" | tr "[:upper:]" "[:lower:]")

        if [[ "${delete_directory}x" == "dx" ]]; then
            read_input "Confirm to delete directory:[${parent}/${directory}]. (y/n), 默认: n ? " "^([Yy]|[Nn])$" "n"
            confirm_delete_directory=$(echo "${read_value}" | tr "[:upper:]" "[:lower:]")
            if [[ "${confirm_delete_directory}x" != "yx" ]]; then
                delete_directory="b"
            fi
        fi

        ## backup or delete
        cd ${parent}
        case ${delete_directory} in
         d)
            LOG_WARN "Delete directory:[${parent}/${directory}]."
            rm -rfv ${directory}
            ;;
         b)
            new_dir=${directory}-$(date "+%Y%m%d-%H%M%S")
            LOG_INFO "Backup directory:[${parent}/${directory}] to [${parent}/${new_dir}]."
            mv -fv ${directory} ${new_dir}
            ;;
         *)
            LOG_WARN "Unknown operation type : [${OPT_TYPE}]"
            exit 1
        esac
    fi
}

function enable_ufw(){
    LOG_INFO "开启防火墙"
    ufw --force enable
    ufw default deny
    ssh_port=`netstat -anp | grep -i -w tcp | grep LISTEN | grep sshd| awk '{print $4}' | cut -f 2 -d ':'`

    LOG_INFO "防火墙 开放 ssh 端口: [${ssh_port}] "
    ufw_port_allow ${ssh_port} "tcp"
}

# allow port and protocol
function ufw_port_allow(){
    # port
    port=$1
    # tcp or udp
    type=$2

    if [[ ! ${port} ]]; then
        LOG_WARN "端口参数为空，不能开启"
        return
    fi

    if [[ ! ${type} ]]; then
        type="tcp"
    fi

    LOG_INFO "Allow port ${port}/${type} in...."

    exist_tcp_and_udp=$(ufw status verbose |awk -F ' ' '{print $1}' |egrep -w "^${port}$") || :
    if [[ ${exist_tcp_and_udp} ]]; then
        # already exists
        exist_rule=`ufw status verbose | egrep -w "^${port}"`
        LOG_WARN "Rule already exist : ${exist_rule} "
        return
    fi

    exist_type=$(ufw status verbose |awk -F ' ' '{print $1}' |egrep -w "^${port}/${type}$") || :
    if [[ ${exist_type} ]]; then
        # already exists
        exist_rule=`ufw status verbose | egrep -w "^${port}/${type}"`
        LOG_WARN "Rule already exist : ${exist_rule} "
        return
    fi

    ufw allow ${port}/${type}
}


function config_ssh(){
    # 脚本说明
    cat << EOF
1. 配置 SSH 服务
    1.1 修改 sshd port
    1.2 禁用密码登陆，仅允许免密登陆
    1.3 禁用 DNS 反向解析
    1.4 GSSAPIAuthentication
2. ufw 开启 ssh 端口
EOF
    
    # change ssh config
    read_input "是否需要修改 SSH 配置, (y/n)? (默认: n) " "^([y]|[n])$" "n"
    change_ssh=${read_value}
    
    if [[ ${change_ssh} == y ]]; then
        read_input "请指定 SSH 新的端口号 (可用范围为0-65535), 默认 27392:  ? " "^([0-9]{1,4}|[1-5][0-9]{4}|6[0-5]{2}[0-3][0-5])$" "27392"
        new_port=${read_value}
    
        echo "请注意修改防火墙，打开 SSH 端口 : ${new_port}"
    
        # update port
        sed -i 's/^Port/#Port/g' /etc/ssh/sshd_config
        # turn off password authentication
        sed -i 's/^PasswordAuthentication/#PasswordAuthentication/g' /etc/ssh/sshd_config
        # turn off dns
        sed -i 's/^UseDNS/#UseDNS/g' /etc/ssh/sshd_config
        # turn off GSSAPIAuthentication
        sed -i 's/^GSSAPIAuthentication/#GSSAPIAuthentication/g' /etc/ssh/sshd_config
    
        echo "Port ${new_port}">> /etc/ssh/sshd_config
        echo "PasswordAuthentication no">> /etc/ssh/sshd_config
        echo "UseDNS no">> /etc/ssh/sshd_config
        echo "GSSAPIAuthentication no">> /etc/ssh/sshd_config
    
        old_ssh_port=`netstat -anp | grep -i -w tcp | grep LISTEN | grep sshd| awk '{print $4}' | cut -f 2 -d ':'`
    
        service sshd restart
    
        # iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${new_port} -j ACCEPT
        # ip6tables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${new_port} -j ACCEPT
        
        LOG_INFO "删除防火墙旧的 SSH 规则: ${old_ssh_port}"
        ufw --force delete allow ${old_ssh_port}/tcp
    
        LOG_INFO "打开防火墙旧的 SSH 规则 : ${new_port}"
        ufw allow ${new_port}/tcp
        ufw status verbose
    fi

}

function generate_cdn_config(){
    echo "使用启用 CDN?"
    select name in "Linux" "Windows" "Mac OS" "UNIX" "Android"
    do
        echo $name
    done
    echo "You have selected $name"

}


################### set bash configurations ###################
# 命令返回非 0 时，就退出
set -o errexit
# 管道命令中任何一个失败，就退出
set -o pipefail
# 遇到不存在的变量就会报错，并停止执行
set -o nounset
# 在执行每一个命令之前把经过变量展开之后的命令打印出来，调试时很有用
#set -o xtrace

# 退出时，执行的命令，做一些收尾工作
trap 'echo -e "Aborted, error $? in command: $BASH_COMMAND"; trap ERR; exit 1' ERR

# Set magic variables for current file & dir
# deploy.sh 脚本所在的目录
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 脚本的全路径，包含脚本文件名
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
# 脚本的名称，不包含扩展名
__base="$(basename ${__file} .sh)"
# 脚本所在的目录的父目录，一般脚本都会在父项目中的子目录，
#     比如: bin, script 等，需要根据场景修改
__root="$(cd "$(dirname "${__dir}")" && pwd)" # <-- change this as it depends on your app
#__root="${__dir}" # <-- change this as it depends on your app
__root=$(realpath -s "${__root}")

#### set vars
export __root
export deploy_root=${__root}/deploy

export CLOUD_FLARE_TOKEN=""
export DOMAIN=""
# *.cloudfront.net
export NGINX_DOMAIN=""
export XRAY_UUID=$(cat /proc/sys/kernel/random/uuid)
export EMAIL=
export EXTERNAL_IP=$(curl https://ipinfo.io/ip)
export ENABLE_PROXY_PROTOCOL=false

#### 常量配置
export NGINX_FALLBACK_PORT="10000"

export XRAY_VLESS_PATH="/api/chat"
export XRAY_VLESS_PORT="10001"

export XRAY_VMESS_PATH="/api/ws"
export XRAY_VMESS_PORT="10002"

export DEFAULT_IP_CRT="/default/fullchain-san.crt"
export DEFAULT_IP_KEY="/default/fullchain-san.key"

export DOMIAN_CRT="/cert/fullchain.pem"
export DOMAIN_KEY="/cert/privkey.pem"


################### add current directory to env PATH ###################
PATH="${__root}:$PATH"

echo "============================================================================================"
for arg in "$@"; do
  case ${arg} in

  init*)
    # 启用防火墙
    enable_ufw
    
    ###### 更新 ssh 配置
    key_word="#INITIALIZED by MoMo"
    if [[ ! $(grep "${key_word}" /etc/ssh/sshd_config) ]] ; then
        config_ssh

        echo "${key_word}">> /etc/ssh/sshd_config
    fi

    install_docker

    check_docker

    install_docker_compose
    ;;

  dep*)
    mkdir -p ${deploy_root}

    read_input "输入域名：" ".+$" ""
    DOMAIN="${read_value}"
    read_input "输入 Cloudflare Token：" ".+$" ""
    CLOUD_FLARE_TOKEN="${read_value}"
    read_input "输入邮箱：" ".+$" ""
    EMAIL="${read_value}"

    echo ""
    LOG_INFO "选择 CDN ?"
    select CDN_CHOICE in "cloudfront" "cloudflare"
    do
        export CDN_CHOICE;
        LOG_INFO "Use CDN: [${CDN_CHOICE}]"
        case $CDN_CHOICE in
            "cloudfront")
                NGINX_DOMAIN="*.cloudfront.net"
                ## Cloudfront only support HTTP proxy type between CDN server and VPS
                ENABLE_PROXY_PROTOCOL="false"
                break
                ;;
            "cloudflare")
                NGINX_DOMAIN="${DOMAIN}"

                echo ""
                LOG_INFO "选择 CDN 和 VPS 的连接方式?"
                select CONNECT_TYPE_CHOICE in "HTTP" "HTTPS"
                do
                    export CONNECT_TYPE_CHOICE;
                    LOG_INFO "Use : [${CONNECT_TYPE_CHOICE}] between [${CDN_CHOICE}] and VPS"
                    case ${CONNECT_TYPE_CHOICE} in
                        "HTTPS")
                            ENABLE_PROXY_PROTOCOL="true"
                            break
                            ;;
                        "HTTP")
                            ENABLE_PROXY_PROTOCOL="false"
                            break
                            ;;
                        *)
                            LOG_WARN "输入错误，请重新输入 !!"
                    esac
                    break
                done
                break
                ;;
            *)
                LOG_WARN "输入错误，请重新输入!!"
        esac
        break
    done

    replace_vars_in_file "${__root}/template/cloudflare.ini.tpl" "${deploy_root}/cloudflare.ini"

    replace_vars_in_file "${__root}/template/xray/server-config.json.tpl" "${deploy_root}/xray/config.json"

    export client_outbound_file="${deploy_root}/xray/client-outbound-${DOMAIN//./-}.json"
    export client_json_file="${deploy_root}/xray/client-config.json"
    replace_vars_in_file "${__root}/template/xray/client-outbounds.json.tpl" ${client_outbound_file}
    export client_outbounds=$(cat ${client_outbound_file})
    replace_vars_in_file "${__root}/template/xray/client-config.json.tpl" ${client_json_file}

    replace_vars_in_file "${__root}/template/nginx/nginx-cdn.conf.tpl" "${deploy_root}/nginx/nginx-${CDN_CHOICE}.conf"
    replace_vars_in_file "${__root}/template/nginx/nginx-xray.conf.tpl" "${deploy_root}/nginx/nginx-xray.conf"

    replace_vars_in_file "${__root}/template/crontab/config.json.tpl" "${deploy_root}/crontab/config.json"

    # generate default-ip-certs
    mkdir -p ${deploy_root}/certs/default

    # generate domain certs
    docker run -it --rm --name certbot \
        -v "${deploy_root}/certs/domain:/etc/letsencrypt" \
        -v "${deploy_root}/cloudflare.ini:/cloudflare.ini" \
        certbot/dns-cloudflare certonly \
        --dns-cloudflare --dns-cloudflare-credentials /cloudflare.ini \
        -m ${EMAIL} \
        --agree-tos \
        --no-eff-email \
        --dns-cloudflare-propagation-seconds 20 \
        -d ${DOMAIN}

    ufw_port_allow 80 "tcp"
    ufw_port_allow 443 "tcp"

    replace_vars_in_file "${__root}/template/docker-compose.yml.tpl" "${deploy_root}/docker-compose-generated.yml.tpl"

    replace_vars_in_file "${__root}/template/xray.sh.tpl" "${__root}/xray.sh"
    chmod +x ${__root}/xray.sh && ln -s -f ${__root}/xray.sh /usr/local/bin/x


    SSH_PORT=$(netstat -anp | grep -i -w tcp | grep LISTEN | grep sshd| awk '{print $4}' | cut -f 2 -d ':')
    #### summarize
    LOG_INFO "================ SUMMARIZE ================"
    echo "Server IP         :   ${EXTERNAL_IP}"
    echo ""
    echo "UUID              :   ${XRAY_UUID}"
    echo "DOMAIN            :   ${DOMAIN}"
    echo ""
    echo "VLESS_PATH        :   ${XRAY_VLESS_PATH}"
    echo "VMESS_PATH        :   ${XRAY_VMESS_PATH}"
    echo ""
    echo "CDN               :   ${CDN_CHOICE}"
    echo "CDN to VPS        :   ${CONNECT_TYPE_CHOICE}"
    echo ""
    echo "Client outbound   : scp -P ${SSH_PORT} root@${EXTERNAL_IP}:${client_outbound_file} ."
    echo "Client config     : scp -P ${SSH_PORT} root@${EXTERNAL_IP}:${client_json_file} ."
    ;;
  esac
done


