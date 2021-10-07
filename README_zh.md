# Cloudflare DDNS

[![ddns](https://img.shields.io/badge/LICENSE-BSD3%20Clause%20Liscense-brightgreen?style=flat-square)](./LICENSE)

[README](./README.md) | [中文說明](./README_zh.md)

用於透過 Cloudflare API 動態更新域名的解析記錄, 支持 A 或 AAAA 記錄類型.

## 應用步驟

### 編輯並執行脚本

首先需要注意你與 `raw.githubusercontent.com` 間的網路連接性. 若存在這一問題, 可以嘗試直接拷貝脚本内容並繼續或使用相關 CDN 服務.

```
curl -o /usr/local/bin/ddns.sh https://raw.githubusercontent.com/fernvenue/cloudflare-ddns/master/ddns.sh
vim /usr/local/bin/ddns.sh
```

在脚本中填充以下賬戶信息:

- `CFKEY`: 你 Cloudflare 賬戶所屬的全局 API 密鑰.
- `CFUSER`: 你 Cloudflare 賬戶所使用的郵件地址.
- `CFZONE_NAME`: 目標域名所屬域, 如 `example.com`.
- `CFRECORD_NAME`: 目標域名, 如 `ddns.example.com`.
- `CFRECORD_TYPE`: 解析類型, 可以是 A 或 AAAA.

**同時你必須先行解析目標域名到一個地址**, 這裏可以是任意合法地址, 稍後可透過脚本自動更正.

在確認賬戶信息無誤后, 可以執行以下代碼來測試可用性:

```
chmod +x /usr/local/bin/ddns.sh
/bin/bash /usr/local/bin/ddns.sh
```

若提示 `no file, need ip.` 請檢查你的賬戶信息是否正確.

### 透過 systemd timer 自動化執行

你可以直接執行下列代碼, 或參照本項目手動編寫 systemd 相關配置, 亦或使用 crontab 自動化執行. 你仍然需要關注你與 `raw.githubusercontent.com` 之間的網路連接性, 若存在這一問題, 可以嘗試直接本項目内容並繼續或使用相關 CDN 服務.

```
curl -o /lib/systemd/system/ddns.service https://raw.githubusercontent.com/fernvenue/cloudflare-ddns/master/ddns.service
curl -o /lib/systemd/system/ddns.timer https://raw.githubusercontent.com/fernvenue/cloudflare-ddns/master/ddns.timer
systemctl enable ddns.timer
systemctl start ddns.timer
systemctl status ddns
```

## 注意事項

默認情況下透過 [icanhazip](https://github.com/major/icanhaz) 獲取公網 IP 地址. 它托管於 Cloudflare 並工作在兩個域上:

- https://ipv4.icanhazip.com
- https://ipv6.icanhazip.com

如果你位於中國大陸或其他與 Cloudflare 網路連接較差的地區, 可以嘗試使用上海交通大學的 API 接口, 它同樣工作在兩個域上:

- https://whatismyip.sjtu.edu.cn
- https://v6.whatismyip.sjtu.edu.cn

同時, 你也可以使用 [fernvenue/workers-scripts](https://github.com/fernvenue/workers-scripts#return-public-ip-as-textplain) 來自建 API 接口服務到 Cloudflare Workers 上.

在 [NGINX](https://nginx.org) 上自建也是非常簡單的:

```
location /ip {
    default_type text/plain;
    return 200 "$remote_addr\n";
}
```

**此外, 修改任何 Cloudflare 賬戶信息后都請確保已同步修改脚本中的相關信息.**

## 更多訊息

- 動態 DNS 概要: https://www.cloudflare.com/learning/dns/glossary/dynamic-dns
- Cloudflare API 接口文檔: https://developers.cloudflare.com/api
