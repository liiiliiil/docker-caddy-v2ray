  {
    "tag": "xray_vmess_ws_cdn",
    "protocol": "vmess",
    "settings": {
      "vnext": [
        {
          "address": "${DOMAIN}",
          "port": 443,
          "users": [
            {
              "id": "${XRAY_UUID}",
              "alterId": 0,
              "security": "none"
            }
          ]
        }
      ]
    },
    "streamSettings": {
      "network": "ws",
      "security": "tls",
      "tlsSettings": {
        "serverName": "${DOMAIN}"
      },
      "wsSettings": {
        "path": "${XRAY_VMESS_PATH}",
        "headers": {
          "Host": "${DOMAIN}"
        }
      }
    },
    "mux": {
      "enabled": true
    }
  },
  {
    "tag": "xray_vless_xtls",
    "protocol": "vless",
    "settings": {
      "vnext": [
        {
          "address": "${EXTERNAL_IP}",
          "port": 443,
          "users": [
            {
              "id": "${XRAY_UUID}",
              "flow": "xtls-rprx-direct",
              "encryption": "none",
              "level": 0
            }
          ]
        }
      ]
    },
    "streamSettings": {
      "network": "tcp",
      "security": "xtls",
      "xtlsSettings": {
        "serverName": "${DOMAIN}"
      }
    }
  },
  {
    "tag": "xray_vless_ws",
    "protocol": "vless",
    "settings": {
      "vnext": [
        {
          "address": "${DOMAIN}",
          // 换成你的域名或服务器 IP（发起请求时无需解析域名了）
          "port": 443,
          "users": [
            {
              "id": "${XRAY_UUID}",
              "encryption": "none",
              "level": 0
            }
          ]
        }
      ]
    },
    "streamSettings": {
      "network": "ws",
      "security": "tls",
      "tlsSettings": {
        "serverName": "${DOMAIN}"
      },
      "wsSettings": {
        "path": "${XRAY_VLESS_PATH}"
        "headers": {
          "Host": "${DOMAIN}"
        }
      }
    }
  }
