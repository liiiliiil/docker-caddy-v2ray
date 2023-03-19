version: "3"
services:
  nginx:
    image: nginx:stable-alpine
    container_name: nginx
    hostname: nginx
    network_mode: "host"
    restart: always
    volumes:
      - ./nginx:/etc/nginx/conf.d/
      - ${__root}/static:/usr/share/nginx/html

  crontab:
    image: willfarrell/crontab
    container_name: crontab
    hostname: crontab
    network_mode: "host"
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./crontab:/opt/crontab
    depends_on:
      - nginx

  xray:
    image: teddysun/xray:1.7.5
    container_name: xray
    hostname: xray
    network_mode: "host"
    restart: always
    labels:
      - acme.autoload.label=true
    volumes:
      - ${deploy_root}/certs/default:/default
      - $${my_empty_variable}{DOMIAN_HOST_CRT}:${DOMIAN_CRT}
      - $${my_empty_variable}{DOMIAN_HOST_KEY}:${DOMAIN_KEY}
      - ./xray:/etc/xray
      - ./logs:/logs
    depends_on:
      - crontab

  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    hostname: watchtower
    network_mode: "host"
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: --cleanup --interval 3600 xray
    depends_on:
      - xray

