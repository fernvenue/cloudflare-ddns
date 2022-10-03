# Cloudflare DDNS

[![cloudflare-ddns](https://img.shields.io/badge/LICENSE-BSD3%20Clause%20Liscense-blue?style=flat-square)](./LICENSE)
[![cloudflare-ddns](https://img.shields.io/badge/GitHub-Cloudflare%20DDNS-blueviolet?style=flat-square&logo=github)](https://github.com/fernvenue/cloudflare-ddns)
[![cloudflare-ddns](https://img.shields.io/badge/GitLab-Cloudflare%20DDNS-orange?style=flat-square&logo=gitlab)](https://gitlab.com/fernvenue/cloudflare-ddns)

A lightweight Cloudflare Dynamic DNS shell script.

## Features

- [x] Support A and AAAA types.
- [x] Work with systemd timer.
- [x] Specific outbound interface.
- [x] Telegram notification.
- [x] Socks proxy for Cloudflare and Telegram APIs.

## Usage

Get and fill in the information in the script:

```
curl -o /usr/local/bin/ddns.sh https://gitlab.com/fernvenue/cloudflare-ddns/-/raw/master/ddns.sh
vim /usr/local/bin/ddns.sh
```

- `CLOUDFLARE_API_KEY`: Global API Key of your Cloudflare account.
- `CLOUDFLARE_RECORD_NAME`: Record name, such as `ddns.example.com`.
- `CLOUDFLARE_RECORD_TYPE`: Record type, can be A or AAAA.
- `CLOUDFLARE_USER_MAIL`: The email address of your Cloudflare account.
- `CLOUDFLARE_ZONE_NAME`: Zone name, such as `example.com`.
- `OUTBOUND_INTERFACE`: Optional, used to specify the outbound interface.
- `SOCKS_ADDR`: Optional, your socks server address, work for Cloudflare and Telegram APIs.
- `SOCKS_PORT`: Optional, your socks server port.
- `TELEGRAM_BOT_ID`: Optional, your telegram bot ID.
- `TELEGRAM_CHAT_ID`: Optional, your telegram account or channel ID.
- `FORCE_UPDATE`: Used to update anyway even if the IP unchanged, default is `false`.

You can also define parameters by flags:

- `-k` = `$CLOUDFLARE_API_KEY`
- `-n` = `$CLOUDFLARE_RECORD_NAME`
- `-t` = `$CLOUDFLARE_RECORD_TYPE`
- `-u` = `$CLOUDFLARE_USER_MAIL`
- `-z` = `$CLOUDFLARE_ZONE_NAME`
- `-i` = `$OUTBOUND_INTERFACE`
- `-a` = `$SOCKS_ADDR`
- `-p` = `$SOCKS_PORT`
- `-b` = `$TELEGRAM_BOT_ID`
- `-c` = `$TELEGRAM_CHAT_ID`
- `-f` = `$FORCE_UPDATE`

Give permission and run. **You must have resolved the target domain name to an address.**

```
chmod +x /usr/local/bin/ddns.sh
/bin/bash /usr/local/bin/ddns.sh
```

Use systemd timer to automate.

```
curl -o /etc/systemd/system/ddns.service https://gitlab.com/fernvenue/cloudflare-ddns/-/raw/master/ddns.service
curl -o /etc/systemd/system/ddns.timer https://gitlab.com/fernvenue/cloudflare-ddns/-/raw/master/ddns.timer
systemctl enable ddns.timer
systemctl start ddns.timer
systemctl status ddns
```

<details><summary>What if I using non-systemd Unix system?</summary>

Maybe you can use [cron](https://en.wikipedia.org/wiki/Cron) to automate it, for example add `*/1 * * * * /usr/local/bin/ddns.sh` to the cron configuration, and the configuration file for a user can be edited by calling `crontab -e` regardless of where the actual implementation stores this file.

</details>

**Notice: if you changed any Cloudflare account information, make sure it is also changed in the script.**

## Links

- [Cloudflare APIs documantation](https://developers.cloudflare.com/api)
- [What is dynamic DNS (DDNS)?](https://www.cloudflare.com/learning/dns/glossary/dynamic-dns)
