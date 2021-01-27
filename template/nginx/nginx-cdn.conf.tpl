server {
    listen 80;
    server_name ${NGINX_DOMAIN};

    location ${XRAY_VLESS_PATH} {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:${XRAY_VLESS_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade $${my_empty_variable}http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $${my_empty_variable}http_host;
        # Show realip in v2ray access.log
        proxy_set_header X-Real-IP $${my_empty_variable}remote_addr;
        proxy_set_header X-Forwarded-For $${my_empty_variable}proxy_add_x_forwarded_for;
    }

    location ${XRAY_VMESS_PATH} {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:${XRAY_VMESS_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade $${my_empty_variable}http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $${my_empty_variable}http_host;
        # Show realip in v2ray access.log
        proxy_set_header X-Real-IP $${my_empty_variable}remote_addr;
        proxy_set_header X-Forwarded-For $${my_empty_variable}proxy_add_x_forwarded_for;
    }

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
}

