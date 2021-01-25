{
  "log": {
    "access": "/logs/x2ray_access.log",
    "error": "/logs/x2ray_error.log",
    "loglevel": "debug"
  },
  "api": {
    "tag": "api",
    "services": [
      "HandlerService",
      "LoggerService",
      "StatsService"
    ]
  },
  "dns": {},
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "outboundTag": "api",
        "inboundTag": [
          "api"
        ]
      },
      {
        "type": "field",
        "outboundTag": "block",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  },
  "policy": {
    "levels": {
      "0": {
        "handshake": 4,
        "connIdle": 300,
        "uplinkOnly": 5,
        "downlinkOnly": 30,
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
      "statsInboundDownlink": true,
      "statsInboundUplink": true
    }
  },
  "inbounds": [
    {
      "tag": "api",
      "listen": "127.0.0.1",
      "port": 10086,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "0.0.0.0"
      }
    },
    {
      "tag": "xtls",
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${XRAY_UUID}",
            "flow": "xtls-rprx-direct",
            "level": 0,
            "email": "love@example.com"
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "dest": ${NGINX_FALLBACK_PORT}
          },
          {
            "path": "${XRAY_VLESS_PATH}",
            "dest": ${XRAY_VLESS_PORT},
            "xver": 1
          },
          {
            "path": "${XRAY_VMESS_PATH}",
            "dest": ${XRAY_VMESS_PORT},
            "xver": 1
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "xtls",
        "xtlsSettings": {
          "alpn": [
            "http/1.1"
          ],
          "certificates": [
            //{
            //	"certificateFile": "${DEFAULT_IP_CRT}/certs/domain
            //	"keyFile": "${DEFAULT_IP_KEY}"
            //},
            {
              "certificateFile": "${DOMIAN_CRT}",
              "keyFile": "${DOMAIN_KEY}"
            }
          ]
        }
      }
    },
    {
      "tag": "vless",
      "port": ${XRAY_VLESS_PORT},
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${XRAY_UUID}",
            "level": 0,
            "email": "love@example.com"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": ${ENABLE_PROXY_PROTOCOL},
          "path": "${XRAY_VLESS_PATH}"
        }
      }
    },
    {
      "tag": "vmess",
      "port": ${XRAY_VMESS_PORT},
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "${XRAY_UUID}",
            "level": 0,
            "email": "love@example.com"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": ${ENABLE_PROXY_PROTOCOL},
          "path": "${XRAY_VMESS_PATH}"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {},
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "block"
    }
  ],
  "transport": {},
  "stats": {},
  "reverse": {}
}

