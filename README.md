
以前部署 ss 的时候，三行命令就可以部署一台 ss server 服务器，超级方便。

现在，喜欢上了 V2ray, V2ray 可以使用 WebSocket + TLS + Web + CDN 的方式，将流量伪装成 HTTPS 流量，同时还能使用 CloudFlare 的免费 CDN，这样就再也不怕自己的 IP 被屏蔽的问题了。

但是配置 V2ray 的 WebSocket + TLS + Web + CDN 步骤太多，而且，稍为不注意还容易出错，所以为了方便搭建，使用 Shell 基于 Docker 做了一个一键部署脚本。

# 准备工作
1. 购买一个域名，找个 xxxx.com ，购买一个自己的域名.
2. 因为要使用 CloudFlare 的 CDN，去 https://www.cloudflare.com/ 注册一个账号，然后添加自己域名到 CloudFlare。CloudFlare 会列出两个 NameServer 需要配置到自己购买域名.
    ![namecheap-set-custom-ns](https://img.tupm.net/2019/09/59F435E69681B8091B72F3EDD75103F8.jpg)
    参考：[CloudFlare免费CDN加速使用方法](https://zhuanlan.zhihu.com/p/29891330)
3. 登录 CloudFlare, 选中一个域名,然后找到右下角有一个 <Get your API token>, 点击下面的 <Global API Key>，记录下这个值和 CloudFlare 的登录邮箱 Mail。

# 运行脚本




# 默认配置

当前配置包含了：
1. WS + TLS + Caddy : 需要 CloudFlare 信息（邮箱 和 Global API Key）和 **域名**，Caddy 绑定 80 和 443，v2ray 绑定 30000 端口。
2. TCP : 默认绑定在 37849 端口。
3. SS : 默认绑定在 22 端口

## 怎么使用
### 第一次运行

**注意：** 需要复制 docker-compose.yml.template 文件，然后***去掉需要开放的端口***前面的 127.0.0.1。
```
git clone https://github.com/yuanmomo/docker-caddy-v2ray.git;
cd v2ray-caddy-docker;
cp docker-compose.yml.template docker-compose.yml;

## 修改 docker-compose.yml 文件，
vim docker-compose.yml;

## 执行脚本初始化
start.sh -i;
```
然后按提示输入域名，邮箱，Global API Key。

如果启动有问题可以用下面两个命令查看日志。

```shell
docker logs caddy
docker logs v2ray 
```

### 重启

```shell
sh start.sh
```
执行脚本即可。

## CloudFlare 的 API Key
### 获取 邮箱 和 Key
1. Login to the Cloudflare account.

2. Go to My Profile.

3. Scroll down to API Keys and locate Global API Key.

4. Click API Key to see your API identifier.

### 原因
使用了 CloudFlare 后，Caddy 使用 acme 申请的 HTTPS 证书无法续签。
>Caddy 为了保证证书不过期，会隔一段时间撤销之前的证书申请一个新的证书。签发证书的机构 Let's Encrypt 为了验证你对网站的所有权，会验证一下域名指向的 IP 地址和发出申请的 IP 地址是否相同。而 Cloudflare 的 name server 隐藏了你原先的服务器 IP，所以自然是对不上的。

![caddy-acme-failed](https://img.tupm.net/2019/09/D016C61768F6D9EC35E58400AF0BDC50.jpg)

所以，使用了 Caddy 的 CloudFlare 插件。