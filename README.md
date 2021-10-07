# Cloudflare DDNS

[![ddns](https://img.shields.io/badge/LICENSE-BSD3%20Clause%20Liscense-brightgreen?style=flat-square)](./LICENSE)

Automatically update the resolution of domain by Cloudflare api, support A and AAAA records.

## Steps for Usage

### Edit and run the script

What you need to pay attention to at this step is the connectivity between your network and `raw.githubusercontent.com`. If your network has this problem, you can try to manually copy to the directory below and continue, or try to use some CDN services.

```
curl -o /usr/local/bin/ddns.sh https://raw.githubusercontent.com/fernvenue/cloudflare-ddns/master/ddns.sh
vim /usr/local/bin/ddns.sh
```

Fill in the following account information:

- `CFKEY`: The Global API key of your Cloudflare account.
- `CFUSER`: The email address you use on Cloudflare.
- `CFZONE_NAME`: Zone name of your domain, such as `example.com`.
- `CFRECORD_NAME`: Domain name of your target, such as `ddns.example.com`.
- `CFRECORD_TYPE`: The type of your record, can be A or AAAA.

**And you must have resolved the target domain name to an address**, can be any address and we will use this script to correct it.

After confirming that the above information is correct, we can run the following code to test it
```
chmod +x /usr/local/bin/ddns.sh
/bin/bash /usr/local/bin/ddns.sh
```

If you get `no file, need ip.` error just check your account information again.

### Use systemd timer to automate

You can run the following code directly, or write it yourself by referring to this project, or just use crontab to automate it. What you still need to pay attention to is the connectivity between your network and `raw.githubusercontent.com`. If your network has this problem, you can try to manually copy to the directory below and continue, or try to use some CDN services.

```
curl -o /lib/systemd/system/ddns.service https://raw.githubusercontent.com/fernvenue/cloudflare-ddns/master/ddns.service
curl -o /lib/systemd/system/ddns.timer https://raw.githubusercontent.com/fernvenue/cloudflare-ddns/master/ddns.timer
systemctl enable ddns.timer
systemctl start ddns.timer
systemctl status ddns
```

## Something else

By default, [icanhazip](https://github.com/major/icanhaz) is used to get the public IP address. It is hosted on Cloudflare and works on two domains:

- https://ipv4.icanhazip.com
- https://ipv6.icanhazip.com

If you are located in mainland China or other areas with poor connectivity to Cloudflare, you can try to use the api of SJTU, which works on two domains:

- https://whatismyip.sjtu.edu.cn
- https://v6.whatismyip.sjtu.edu.cn

At the same time, you can also try to use [fernvenue/workers-scripts](https://github.com/fernvenue/workers-scripts#return-public-ip-as-textplain) to build your own api service on Cloudflare Workers.  

It is also simple on [NGINX](https://nginx.org):

```
location /ip {
    default_type text/plain;
    return 200 "$remote_addr\n";
}
```

**In addition, if you change any Cloudflare account information, make sure it is also changed in the script.**

## For more information

- Dynamic DNS: https://www.cloudflare.com/learning/dns/glossary/dynamic-dns
- Cloudflare API: https://developers.cloudflare.com/api
