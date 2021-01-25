{
  "log": {
    "loglevel": "debug"
  },
  "inbounds": [
    {
      "tag": "all-socks-in-1",
      "port": 11087,
      "listen": "0.0.0.0",
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "timeout": 0,
        "udp": true
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
    {
      "tag": "all-socks-in-2",
      "port": 11088,
      "listen": "0.0.0.0",
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "timeout": 0,
        "udp": true
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
    {
      "tag": "all-socks-in-3",
      "port": 11089,
      "listen": "0.0.0.0",
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "timeout": 0,
        "udp": true
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
  "outbounds": [
    ${client_outbounds}
    ,{
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "AsIs"
      },
      "streamSettings": {},
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    },
    {
      "protocol": "dns",
      "tag": "dns-out"
    }
  ],
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "inboundTag": [
          "all-socks-in-1"
        ],
        "outboundTag": "xray_vmess_ws_cdn"
      },
      {
        "type": "field",
        "inboundTag": [
          "all-socks-in-2"
        ],
        "outboundTag": "xray_vless_xtls"
      },
      {
        "type": "field",
        "inboundTag": [
          "all-socks-in-3"
        ],
        "outboundTag": "xray_vless_ws"
      }
    ]
  }
}