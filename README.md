# 简介
以前部署 ss 的时候，三行命令就可以部署一台 ss server 服务器，超级方便。

现在，喜欢上了 V2ray, V2ray 可以使用 WebSocket + TLS + Web + CDN 的方式，将流量伪装成 HTTPS 流量，同时还能使用 CloudFlare 的免费 CDN，这样就再也不怕自己的 IP 被屏蔽的问题了。

但是配置 V2ray 的 WebSocket + TLS + Web + CDN 步骤太多，而且，稍为不注意还容易出错，所以为了方便搭建，使用 Shell 基于 Docker 做了一个一键部署脚本。

# 脚本功能
## 初始化 Server
1. 设置 Server 的 DNS 为 8.8.8.8 和 8.8.4.4
2. 安装常用工具: vim mosh dnsutils net-tools mlocate wget
3. 修改 SSH 端口，禁止密码登陆（可选）
4. 安装 docker 和 docker-compose
5. 安装 ufw，配置防火墙端口

**注意:** 如果有修改 SSH 端口，脚本会自动开放端口，但是最好还是检查一下防火墙。

## 生成 V2Ray 配置
V2Ray 可以根据提示生成三种连接方式:

### 1. Shadowsocks(SS) 
端口 : 默认 39832    
密码 : 随机 24 长度字符串。     
加密方式 : chacha20-ietf-poly1305   

### 2. V2Ray tcp 直连
端口 : 默认 37849    
UUID : 自动生成

### 3. V2Ray WebSocket + TLS + Web + CDN(CloudFlare)，
域名 : 自行配置     
端口 : Caddy 绑定 80 和 443（不能修改）    
UUID : 自动生成


# 依赖环境
Debian 9+ / Ubuntu 16.04 + (测试通过，可用)     
CentOS 7+ (没有测试，如果有问题，请提交到 Issue)

# 准备工作
如果使用 SS 和 tcp 直接， 只需要购买一个 VPS。

如果需要使用 WebSocket + TLS + Web + CDN ，需要购买域名和注册 CloudFlare 账号。

1. 购买一个域名，找个 xxxx.com ，购买一个自己的域名.
2. 因为要使用 CloudFlare 的 CDN，去 https://www.cloudflare.com/ 注册一个账号，然后添加自己域名到 CloudFlare。CloudFlare 会列出两个 NameServer 需要配置到自己购买域名.
    ![namecheap-set-custom-ns](https://img.tupm.net/2019/09/59F435E69681B8091B72F3EDD75103F8.jpg)
    参考：[CloudFlare免费CDN加速使用方法](https://zhuanlan.zhihu.com/p/29891330)
3. 登录 CloudFlare, 选中一个域名,然后找到右下角有一个 &lt;Get your API token&gt;, 点击下面的 &lt;Get your API token&gt;，记录下这个值和 CloudFlare 的登录邮箱 Mail。

# 脚本使用

## 第一次安装
根据不同的系统执行下面的命令:

```shell
# Debian / Ubuntu
sed -i 's/^nameserver.*$//g' /etc/resolv.conf && echo "nameserver 8.8.8.8\nnameserver 8.8.4.4\n" >> /etc/resolv.conf \
    && sed -i '/^$/d' /etc/resolv.conf \
    && apt -y update && apt -y upgrade && apt install -y curl git vim dnsutils net-tools mlocate wget ufw gettext \
    && git clone https://github.com/yuanmomo/docker-caddy-v2ray.git \
    && cd docker-caddy-v2ray && bash caddy-v2ray-docker.sh -i -c

# REHL / CentOS
sed -i 's/^nameserver.*$//g' /etc/resolv.conf && echo "nameserver 8.8.8.8\nnameserver 8.8.4.4\n" >> /etc/resolv.conf \
    && sed -i '/^$/d' /etc/resolv.conf \
    && yum -y update && yum install -y epel-release && yum install -y curl git vim bind-utils net-tools mlocate wget ufw gettext \
    && git clone https://github.com/yuanmomo/docker-caddy-v2ray.git \
    && cd docker-caddy-v2ray && bash caddy-v2ray-docker.sh -i -c
```
**说明:**

命令会自动安装 git 和curl，clone 仓库到本地，运行 caddy-v2ray-docker.sh 脚本。脚本接受两个参数:

| 参数         | 是否必须| 是否有值           | 说明     |
| ------------- |:--------:|:--------:|:-----|
| -i | 否 | 否| 是否初始化 Server      |
| -c | 否 | 否| 是否重新配置 V2Ray       |

如果不加参数表示不执行相应的操作。

## 更新
```shell
git pull && bash caddy-v2ray-docker.sh
```

## 重启
不加参数运行脚本即可

```shell
bash caddy-v2ray-docker.sh
```

## 查看日志
### 启动日志
查看容器的启动日志

```shell
docker logs v2ray
docker logs caddy
```
### 应用日志
应用的日志在当前目录的 log 目录下


# 备注
## 1. 为什么需要 CloudFlare Global API Key ？
使用了 CloudFlare 后，Caddy 使用 acme 申请的 HTTPS 证书无法续签。
>Caddy 为了保证证书不过期，会隔一段时间撤销之前的证书申请一个新的证书。签发证书的机构 Let's Encrypt 为了验证你对网站的所有权，会验证一下域名指向的 IP 地址和发出申请的 IP 地址是否相同。而 Cloudflare 的 name server 隐藏了你原先的服务器 IP，所以自然是对不上的。

![caddy-acme-failed](https://img.tupm.net/2019/09/D016C61768F6D9EC35E58400AF0BDC50.jpg)

所以，需要使用 Caddy 的 CloudFlare 插件。