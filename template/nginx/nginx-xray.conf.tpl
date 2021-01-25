server {
    listen ${NGINX_FALLBACK_PORT} ;
    server_name _;
    location / {
	    root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
}

server {
    listen     80  default_server;
    server_name _;
    location / {
        return 301 https://$${my_empty_variable}host$${my_empty_variable}request_uri;
    }
}


