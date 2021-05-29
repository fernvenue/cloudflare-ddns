# cloudflare-ddns
[![ddns](https://img.shields.io/badge/LICENSE-BSD3%20Clause%20Liscense-brightgreen?style=flat-square)](https://en.wikipedia.org/wiki/BSD_licenses#3-clause_license_(%22BSD_License_2.0%22,_%22Revised_BSD_License%22,_%22New_BSD_License%22,_or_%22Modified_BSD_License%22))

## Edit

Fill in the relevant account information in the script.<br>
**And you must have resolved the target domain name to an address.**

```
curl -o /usr/local/bin/ddns.sh https://raw.githubusercontent.com/fernvenue/cloudflare-ddns/master/ddns.sh
vim /usr/local/bin/ddns.sh
```

**DO NOT** forget the following parts:

* CFKEY=
* CFUSER=
* CFZONE_NAME=
* CFRECORD_NAME=
* CFRECORD_TYPE=

About the type: IPv4 addresses are A records, and IPv6 addresses are AAAA records.<br>
**You must use Global API Key for this script.**

## Run

```
chmod +x /usr/local/bin/ddns.sh
/bin/bash /usr/local/bin/ddns.sh
```

## Auto

```
curl -o /lib/systemd/system/ddns.service https://raw.githubusercontent.com/fernvenue/cloudflare-ddns/master/ddns.service
curl -o /lib/systemd/system/ddns.timer https://raw.githubusercontent.com/fernvenue/cloudflare-ddns/master/ddns.timer
systemctl enable ddns.timer
systemctl start ddns.timer
systemctl status ddns
```

## *issue

If you encounter problems with `no file, need ip.` please check your account information.
