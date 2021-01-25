[
  {
    "comment": "renew certs",
    "onstart": true,
    "schedule": "0 0 */5 * *",
    "command": "renew --dns-cloudflare --dns-cloudflare-credentials /cloudflare.ini",
    "dockerargs": "--rm -v ${deploy_root}/certs/domain:/etc/letsencrypt -v ${deploy_root}/cloudflare.ini:/cloudflare.ini",
    "image": "certbot/dns-cloudflare",
    "trigger": [
      {
        "command": "echo 'restart xray' && docker restart xray",
        "container": "crontab"
      }
    ]
  }
]
