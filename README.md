
# 简介
该工具是 [Xray-core](https://github.com/XTLS/Xray-core) 服务的一键部署工具，支持：

1. 一键部署 Xray-core 服务
2. 自动生成 Xray-core **客户端** 配置文件中 outbounds 配置
3. CDN (Cloudflare 和 Cloudfront)

# 依赖环境
Debian 9+ / Ubuntu 16.04 + (测试通过，可用)     
CentOS 7+ (没有测试，如果有问题，请提交到 Issue)

# 使用教程

## 购买 VPS
在服务提供商（搬瓦工，`VirMach`，`AWS lightsail` 都可以）购买一台虚拟主机 VPS，推荐安装 `Debian 10` 系统。

**购买的 VPS，需要记录外网 IP 地址，比如：160.x.x.x**

## 申请域名
由于 `Xray-core` 使用 `TLS(XTLS)` 加密数据，申请一个域名，使用域名申请证书，供 `Xray-core` 使用。

由于 Cloudflare 不再支持 `.cf`, `.ga`, `.gq`, `.ml`, `.tk` 免费域名通过 API 动态修改 DNS。所以，**不能** 从 `freenom` 申请免费域名使用。


**域名需要托管到 Cloudflare，然后通过创建二级域名的方式使用**

## Cloudflare
点击 [注册 Cloudflare](https://dash.cloudflare.com/sign-up) 注册一个 Cloudflare 账号。

### 域名托管
将申请的域名托管到 Cloudflare：在域名提供商设置 `Nameservers` 为 Cloudflare 的 DNS Nameservers。

```Bash
# Cloudflare 的两个 DNS Nameservers
adam.ns.cloudflare.com

serena.ns.cloudflare.com
```
在添加后，需要等待几分钟，Cloudflare 在验证域名所有权后，即可对域名进行操作和配置。

在 DNS 选项中，添加一个二级域名的 DNS 解析记录到 VPS 的 IP 地址，如图：

![add-a-record](https://img.tupm.net/2021/01/8F1E7084F75A9A188D68B1F4E4473F0C.jpg)


**保存二级域名，在部署时，需要填入**

### 申请 Token
VPS 对域名申请证书时，由于使用了 DNS，那么在验证域名的所有权时，请求会发到 CDN 的主机，而不是 VPS 主机，会导致验证失败。所以，申请一个 Token，可以用来在 Cloudflare 修改 DNS 解析记录，一次来通过所有权验证。
 
点击 [Token 申请](https://dash.cloudflare.com/profile/api-tokens) 登陆 Cloudflare，依次点击 《我的个人资料》--> 《API 令牌》--> 《API 令牌 - 创建令牌》--> 《编辑区域 DNS》，如图：


![cloudflare-apply-token](https://img.tupm.net/2021/01/DC71DFF6B5D6C31404BE853A4868BFA0.jpg)

保存后，即会生成一个 API 令牌。 

**保存 API 令牌，在部署时，需要填入**

###  设置 SSL/TLS
配置 CDN 转发请求到 VPS 时的代理方式，如图：

![CDN-VPS](https://img.tupm.net/2021/01/5AF9C629C2EE89720B62F8B386854CD2.jpg)

**部署时，需要选择：CDN 和 VPS 的连接方式？需要根据该配置进行填入**

### 部署
根据不同的系统执行下面的命令 :

```shell
# Debian / Ubuntu
apt -y update  \
    && apt -y upgrade  \
    && apt install -y curl \
    && bash <(curl -s -L https://git.io/JtcqM)

# REHL / CentOS
yum -y update \
    && yum install -y epel-release  \
    && yum install -y curl \
    && bash <(curl -s -L https://git.io/JtcqM)

```
脚本部署中，按照提示，依次输入：

* 二级域名
* API 令牌（Token）
* 邮箱（用来接受证书信息）
* 选择 2 cloudflare
* 根据设置 SSL/TLS 的配置选择相应的方式

![deploy-process](https://img.tupm.net/2021/01/C7E9CD99E2430737773F52CDEB5DEDAD.jpg)

部署后，会输入详细配置信息和 Xray-core 的 **两个** 客户端配置文件:

* 只包含 outbounds 配置
* 整个 Xray-core 的客户端配置（包含 outbounds）

![deploy-sumerize](https://img.tupm.net/2021/01/B8903337FA8B7242687D06168459B6B2.jpg)

### 启动
部署后，默认会安装一个 `x` 命令，使用 `x s` 命令启动服务。

```Bash
# 启动 
$ x s

# 停止
$ x p

# 重启
$ x r

# 查看帮助文档
$ x h

### 查看 x 命令 
$ ls -al /usr/local/bin/x
lrwxrwxrwx 1 root root 32 Jan 26 18:42 /usr/local/bin/x -> /root/docker-caddy-v2ray/xray.sh
```

## 测试部署结果

使用部署结果中输出的命令下载 客户端完整配置：

客户端需要安装 Xray-core 服务，参考：[Xray-core 安装](https://github.com/XTLS/Xray-core#installation)

```Bash
# 进入 Xray-core 配置目录
cd /usr/local/etc/xray/

# 下载客户端配置文件
scp -P [SSh-端口] root@[VPS-IP]:/root/docker-caddy-v2ray/deploy/xray/client-config.json .
```

使用 curl 检查部署结果

```Bash
# 运行 Xray-core
xray run -config=/usr/local/etc/xray/client-config.json

# 
```

# 部署说明
## 自动更新

一键部署工具，会启动一个 `watchtower` 容器，每天会自动拉取 `teddysun/xray:latest` 镜像，并重启，做到自动更新服务端的 Xray-core 服务。

## 代理方式
* Vless + XTLS
    * 如果 VPS 的线路比较好，可以直接使用此代理方式

* CDN(Cloudflare) + Vless + WS
    * 如果 VPS 线路一般，推荐使用 CDN 的方式
    
* CDN(Cloudflare) + VMess + WS 
    * 如果 VPS 线路一般，推荐使用 CDN 的方式


关于代理方式的详细配置，请参考：`deploy/xray/client-outbound-{域名}.json` 文件

