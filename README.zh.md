# Cloudflare DDNS

[![cloudflare-ddns](https://img.shields.io/badge/LICENSE-BSD3%20Clause%20Liscense-blue?style=flat-square)](./LICENSE)
[![cloudflare-ddns](https://img.shields.io/badge/GitHub-Cloudflare%20DDNS-blueviolet?style=flat-square&logo=github)](https://github.com/fernvenue/cloudflare-ddns)

輕量級 Cloudflare DDNS 腳本.

## 特性

- [x] **雙棧支援**: 支援 IPv4 和 IPv6;
- [x] **多記錄支援**: 支援同時更新多個記錄;
- [x] **智慧監測**: 僅在 IP 地址變動時更新 DNS 記錄;
- [x] **自動緩存**: 自動緩存 DNS 記錄及 zone 信息, 提升性能;
- [x] **多認證方式支援**: 支援 Cloudflare API Token 及 Legacy API Key 認證;
- [x] **代理協議支援**: 支援對 API 請求配置 Socks 代理;
- [x] **Systemd 支援**: 提供 service/timer 示例及動態用戶支援;
- [x] **Telegram 推送**: 可讀性強的 Telegram 通知推送;
- [x] **靈活配置**: 支援命令行參數傳遞與環境變量配置;

## 使用方法

獲取腳本:

```
curl -o /usr/local/bin/cloudflare-ddns.sh https://raw.githubusercontent.com/fernvenue/cloudflare-ddns/refs/heads/master/cloudflare-ddns.sh
vim /usr/local/bin/cloudflare-ddns.sh
```

賦予可執行權限並運行即可, **在運行之前務必確認對應的域名已有記錄**, 否則腳本無法找到需要更新的記錄.

如需詳細的幫助信息, 可以使用:

```bash
./cloudflare-ddns.sh --help
```

### 環境變量

- `CLOUDFLARE_API_TOKEN`: 對應 Cloudflare 賬戶的 API Token (建議);
- `CLOUDFLARE_API_KEY`: 對應 Cloudflare 賬戶的全局 API;
- `CLOUDFLARE_RECORD_NAMES`: 目標記錄名稱, 如 `ddns.example.com` 或 `ddns01.example.com,ddns02.example.com`;
- `CLOUDFLARE_RECORD_TYPES`: 記錄類型, 可以為 `4` (A) 或 `6` (AAAA), 與記錄名稱一一對應, 如 `4,6,4`;
- `CLOUDFLARE_USER_MAIL`: 對應 Cloudflare 賬戶的郵件地址;
- `CLOUDFLARE_ZONE_NAME`: 對應域的名稱, 如 `example.com`;
- `OUTBOUND_INTERFACE`: 可選項, 用於指定網卡;
- `SOCKS_ADDR`: 可選項, 用於為 API 請求 (Cloudflare 與 Telegram) 配置 Socks 代理, IP 檢測不經過此代理;
- `SOCKS_PORT`: 可選項, 對應 Socks 代理的端口;
- `TELEGRAM_BOT_ID`: 可選項, Telegram 機器人對應的 ID;
- `TELEGRAM_CHAT_ID`: 可選項, Telegram 推送的目標對話;
- `CUSTOM_TELEGRAM_ENDPOINT`: 可選項, 用於自定義 Telegram 推送所用的 API 域名;
- `FORCE_UPDATE`: 強制更新, 即使 IP 沒有變化也更新 DNS 記錄;

### 命令行選項

- `--cloudflare-api-token TOKEN` = `$CLOUDFLARE_API_TOKEN`
- `--cloudflare-api-key KEY` = `$CLOUDFLARE_API_KEY`
- `--cloudflare-record-names NAMES` = `$CLOUDFLARE_RECORD_NAMES`
- `--cloudflare-record-types TYPES` = `$CLOUDFLARE_RECORD_TYPES`
- `--cloudflare-user-mail EMAIL` = `$CLOUDFLARE_USER_MAIL`
- `--cloudflare-zone-name NAME` = `$CLOUDFLARE_ZONE_NAME`
- `--outbound-interface IFACE` = `$OUTBOUND_INTERFACE`
- `--socks-addr ADDR` = `$SOCKS_ADDR`
- `--socks-port PORT` = `$SOCKS_PORT`
- `--telegram-bot-id ID` = `$TELEGRAM_BOT_ID`
- `--telegram-chat-id ID` = `$TELEGRAM_CHAT_ID`
- `--custom-telegram-endpoint DOMAIN` = `$CUSTOM_TELEGRAM_ENDPOINT`
- `--force-update` = `$FORCE_UPDATE`

### Systemd

移步 [`cloudflare-ddns.service`](./cloudflare-ddns.service) 和 [`cloudflare-ddns.timer`](./cloudflare-ddns.timer) 參考標準的 systemd service 及 systemd timer 示例.

### 系統依賴

腳本需要在系統中安裝以下工具:

- **curl** - 用於向 Cloudflare API 和 IP 檢測服務發送 HTTP 請求;
- **jq** - 用於 JSON 解析和配置文件操作;
- **awk** - 用於文本處理 (通常預裝);
- **grep** - 用於模式匹配 (通常預裝);
- **date** - 用於時間戳生成 (通常預裝);

## 示例

以下示例是一些常見的應用場景, 僅供參考. 對於生產環境的部署, 建議搭配 systemd service 及 systemd timer 使用.

### 單個 DNS 記錄更新 (僅 IPv4)

使用 API token 更新單個 A 記錄:

```bash
./cloudflare-ddns.sh \
  --cloudflare-api-token "your-cloudflare-api-token" \
  --cloudflare-user-mail "your-email@example.com" \
  --cloudflare-zone-name "example.com" \
  --cloudflare-record-names "ddns.example.com" \
  --cloudflare-record-types "4"
```

### 單個 DNS 記錄更新 (僅 IPv6)

使用 API token 更新單個 AAAA 記錄:

```bash
./cloudflare-ddns.sh \
  --cloudflare-api-token "your-cloudflare-api-token" \
  --cloudflare-user-mail "your-email@example.com" \
  --cloudflare-zone-name "example.com" \
  --cloudflare-record-names "ipv6.example.com" \
  --cloudflare-record-types "6"
```

### 單個域名同時更新 IPv4 和 IPv6

為同一個域名同時更新 A 和 AAAA 記錄 (注意域名重覆):

```bash
./cloudflare-ddns.sh \
  --cloudflare-api-token "your-cloudflare-api-token" \
  --cloudflare-user-mail "your-email@example.com" \
  --cloudflare-zone-name "example.com" \
  --cloudflare-record-names "ddns.example.com,ddns.example.com" \
  --cloudflare-record-types "4,6"
```

在此示例中:
- 第一個 `ddns.example.com` 獲得 A 記錄 (IPv4)
- 第二個 `ddns.example.com` 獲得 AAAA 記錄 (IPv6)

### 多個 DNS 記錄更新 (相同類型)

更新多個相同類型的記錄 (僅 IPv4):

```bash
./cloudflare-ddns.sh \
  --cloudflare-api-token "your-cloudflare-api-token" \
  --cloudflare-user-mail "your-email@example.com" \
  --cloudflare-zone-name "example.com" \
  --cloudflare-record-names "ddns.example.com,api.example.com,home.example.com" \
  --cloudflare-record-types "4,4,4"
```

### 多個 DNS 記錄使用不同類型 (一對一映射)

使用不同類型更新不同記錄 (每個記錄名稱對應每個記錄類型):

```bash
./cloudflare-ddns.sh \
  --cloudflare-api-token "your-cloudflare-api-token" \
  --cloudflare-user-mail "your-email@example.com" \
  --cloudflare-zone-name "example.com" \
  --cloudflare-record-names "api.example.com,ipv6.example.com,home.example.com" \
  --cloudflare-record-types "4,6,4"
```

在此示例中:
- `api.example.com` 獲得 A 記錄 (IPv4)
- `ipv6.example.com` 獲得 AAAA 記錄 (IPv6)
- `home.example.com` 獲得 A 記錄 (IPv4)

### 使用環境變量

```bash
export CLOUDFLARE_API_TOKEN="your-cloudflare-api-token"
export CLOUDFLARE_USER_MAIL="your-email@example.com"
export CLOUDFLARE_ZONE_NAME="example.com"
export CLOUDFLARE_RECORD_NAMES="api.example.com,ipv6.example.com,home.example.com"
export CLOUDFLARE_RECORD_TYPES="4,6,4"

./cloudflare-ddns.sh
```

### 配合 Telegram 通知

```bash
./cloudflare-ddns.sh \
  --cloudflare-api-token "your-cloudflare-api-token" \
  --cloudflare-user-mail "your-email@example.com" \
  --cloudflare-zone-name "example.com" \
  --cloudflare-record-names "ddns.example.com" \
  --cloudflare-record-types "4" \
  --telegram-bot-id "123456789:ABCdefGHIjklMNOpqrsTUVwxyz" \
  --telegram-chat-id "-1001234567890"
```

### 使用自定義 Telegram 端點

使用自定義 Telegram API 域名:

```bash
./cloudflare-ddns.sh \
  --cloudflare-api-token "your-cloudflare-api-token" \
  --cloudflare-user-mail "your-email@example.com" \
  --cloudflare-zone-name "example.com" \
  --cloudflare-record-names "ddns.example.com" \
  --cloudflare-record-types "4" \
  --telegram-bot-id "123456789:ABCdefGHIjklMNOpqrsTUVwxyz" \
  --telegram-chat-id "-1001234567890" \
  --custom-telegram-endpoint "my-telegram-api.example.com"
```

### 使用 Socks 代理

為 API 請求使用 Socks 代理:

```bash
./cloudflare-ddns.sh \
  --cloudflare-api-token "your-cloudflare-api-token" \
  --cloudflare-user-mail "your-email@example.com" \
  --cloudflare-zone-name "example.com" \
  --cloudflare-record-names "ddns.example.com" \
  --cloudflare-record-types "4" \
  --socks-addr "[::1]" \
  --socks-port "1080"
```

### 強制更新

即使 IP 地址沒有變化也強制更新:

```bash
./cloudflare-ddns.sh \
  --cloudflare-api-token "your-cloudflare-api-token" \
  --cloudflare-user-mail "your-email@example.com" \
  --cloudflare-zone-name "example.com" \
  --cloudflare-record-names "ddns.example.com" \
  --cloudflare-record-types "4" \
  --force-update
```