## 是什么？
docker, Caddy, v2ray的一键式启动脚本.

当前配置包含了：
1. WS + TLS + Caddy : 需要邮箱和域名，Caddy 绑定 80 和 443，v2ray 绑定 30000 端口。
2. TCP : 默认绑定在 37849 端口。
3. SS : 默认绑定在 22 端口

## 怎么使用
### 第一次运行

**注意：** 需要复制 docker-compose.yml.template 文件，然后***去掉需要开放的端口***前面的 127.0.0.1。
```
git clone https://github.com/yuanmomo/docker-caddy-v2ray.git;
cd v2ray-caddy-docker;
cp docker-compose.yml.template docker-compose.yml;

## 修改 docker-compose.yml 文件，选择开放指定的端口
vim docker-compose.yml;

## 执行脚本初始化
start.sh -i;
```
然后按提示输入域名和邮箱。

如果使用了 CloudFlare ，注意在第一次启动的时候，因为需要去申请证书，验证，所以不要开启 CDN。否则 Caddy 会启动失败。

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