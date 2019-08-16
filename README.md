## 是什么？
docker, Caddy, v2ray的一键式启动脚本.

当前配置的是 WS + TLS 的方式，所以需要域名。

## 怎么使用
### 第一次运行

```
git clone https://github.com/yuanmomo/docker-caddy-v2ray.git && cd v2ray-caddy-docker && start.sh -i 
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