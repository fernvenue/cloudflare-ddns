# Cloudflare DDNS

[![cloudflare-ddns](https://img.shields.io/badge/LICENSE-BSD3%20Clause%20Liscense-blue?style=flat-square)](./LICENSE)
[![cloudflare-ddns](https://img.shields.io/badge/GitHub-Cloudflare%20DDNS-blueviolet?style=flat-square&logo=github)](https://github.com/fernvenue/cloudflare-ddns)

A lightweight Cloudflare Dynamic DNS shell script.

## Features

- [x] **IPv4 & IPv6 Support**: A and AAAA record types with batch processing;
- [x] **Multi-Record Updates**: Bulk operations with one-to-one type mapping;
- [x] **Smart IP Detection**: Only updates when IP actually changes;
- [x] **Auto Caching**: DNS record and zone ID caching for optimal performance;
- [x] **Secure Authentication**: API tokens and legacy API key support;
- [x] **SOCKS Proxy**: Full proxy support for all API calls;
- [x] **Systemd Integration**: Complete service/timer with security isolation;
- [x] **Telegram Notifications**: Rich status updates with error reporting;
- [x] **Flexible Configuration**: Environment variables and CLI parameters;

## Usage

Get and fill in the information in the script:

```
curl -o /usr/local/bin/cloudflare-ddns.sh https://raw.githubusercontent.com/fernvenue/cloudflare-ddns/refs/heads/master/cloudflare-ddns.sh
vim /usr/local/bin/cloudflare-ddns.sh
```

- `CLOUDFLARE_API_TOKEN`: API Token of your Cloudflare account (preferred).
- `CLOUDFLARE_API_KEY`: Global API Key of your Cloudflare account (legacy).
- `CLOUDFLARE_RECORD_NAMES`: Comma-separated record names, such as `ddns.example.com` or `ddns.example.com,api.example.com`.
- `CLOUDFLARE_RECORD_TYPES`: Record types, must be 4 (A) or 6 (AAAA). Must be comma-separated to correspond one-to-one with record names. No default value.
- `CLOUDFLARE_USER_MAIL`: The email address of your Cloudflare account.
- `CLOUDFLARE_ZONE_NAME`: Zone name, such as `example.com`.
- `OUTBOUND_INTERFACE`: Optional, used to specify the outbound interface.
- `SOCKS_ADDR`: Optional, your socks server address, work for Cloudflare and Telegram APIs.
- `SOCKS_PORT`: Optional, your socks server port.
- `TELEGRAM_BOT_ID`: Optional, your telegram bot ID.
- `TELEGRAM_CHAT_ID`: Optional, your telegram account or channel ID.
- `CUSTOM_TELEGRAM_ENDPOINT`: Optional, custom Telegram API domain (default: api.telegram.org).
- `FORCE_UPDATE`: Used to update anyway even if the IP unchanged, default is `false`.

You can also define parameters by command line options:

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

Give permission and run. **You must have resolved the target domain name to an address.**

For detailed help information, you can use:
```bash
./cloudflare-ddns.sh --help
```

We also provide systemd service and timer configuration files for automated execution, go check [`cloudflare-ddns.service`](./cloudflare-ddns.service) and [`cloudflare-ddns.timer`](./cloudflare-ddns.timer).

### System Dependencies
The script requires the following tools to be installed on your system:

- **bash** - Shell interpreter (usually pre-installed on most Linux distributions);
- **curl** - For making HTTP requests to Cloudflare API and IP detection services;
- **jq** - For JSON parsing and manipulation of configuration files;
- **awk** - For text processing (usually pre-installed);
- **grep** - For pattern matching (usually pre-installed);
- **date** - For timestamp generation (usually pre-installed);

## Examples

### Single DNS Record Update (IPv4 only)

Update a single A record with API token:

```bash
./cloudflare-ddns.sh \
  --cloudflare-api-token "your-cloudflare-api-token" \
  --cloudflare-user-mail "your-email@example.com" \
  --cloudflare-zone-name "example.com" \
  --cloudflare-record-names "ddns.example.com" \
  --cloudflare-record-types "4"
```

### Single DNS Record Update (IPv6 only)

Update records with AAAA records only:

```bash
./cloudflare-ddns.sh \
  --cloudflare-api-token "your-cloudflare-api-token" \
  --cloudflare-user-mail "your-email@example.com" \
  --cloudflare-zone-name "example.com" \
  --cloudflare-record-names "ipv6.example.com" \
  --cloudflare-record-types "6"
```

### Single Domain with Both IPv4 and IPv6

Update both A and AAAA records for the same domain (note the repeated domain name):

```bash
./cloudflare-ddns.sh \
  --cloudflare-api-token "your-cloudflare-api-token" \
  --cloudflare-user-mail "your-email@example.com" \
  --cloudflare-zone-name "example.com" \
  --cloudflare-record-names "ddns.example.com,ddns.example.com" \
  --cloudflare-record-types "4,6"
```

In this example:
- First `ddns.example.com` gets A record (IPv4)
- Second `ddns.example.com` gets AAAA record (IPv6)

### Multiple DNS Records Update (Same Type)

Update multiple records with the same type (IPv4 only):

```bash
./cloudflare-ddns.sh \
  --cloudflare-api-token "your-cloudflare-api-token" \
  --cloudflare-user-mail "your-email@example.com" \
  --cloudflare-zone-name "example.com" \
  --cloudflare-record-names "ddns.example.com,api.example.com,home.example.com" \
  --cloudflare-record-types "4,4,4"
```

### Multiple DNS Records with Different Types (One-to-One Mapping)

Update different records with different types (each record name corresponds to each record type):

```bash
./cloudflare-ddns.sh \
  --cloudflare-api-token "your-cloudflare-api-token" \
  --cloudflare-user-mail "your-email@example.com" \
  --cloudflare-zone-name "example.com" \
  --cloudflare-record-names "api.example.com,ipv6.example.com,home.example.com" \
  --cloudflare-record-types "4,6,4"
```

In this example:
- `api.example.com` gets A record (IPv4)
- `ipv6.example.com` gets AAAA record (IPv6)
- `home.example.com` gets A record (IPv4)

### Using Environment Variables

You can also set environment variables instead of command line arguments:

```bash
export CLOUDFLARE_API_TOKEN="your-cloudflare-api-token"
export CLOUDFLARE_USER_MAIL="your-email@example.com"
export CLOUDFLARE_ZONE_NAME="example.com"
export CLOUDFLARE_RECORD_NAMES="api.example.com,ipv6.example.com,home.example.com"
export CLOUDFLARE_RECORD_TYPES="4,6,4"

./cloudflare-ddns.sh
```

### With Telegram Notifications

Enable Telegram notifications for DNS updates:

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

### With Custom Telegram Endpoint

Use custom Telegram API domain (useful for proxies or alternative endpoints):

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

### With SOCKS Proxy

Use SOCKS proxy for API requests:

```bash
./cloudflare-ddns.sh \
  --cloudflare-api-token "your-cloudflare-api-token" \
  --cloudflare-user-mail "your-email@example.com" \
  --cloudflare-zone-name "example.com" \
  --cloudflare-record-names "ddns.example.com" \
  --cloudflare-record-types "4" \
  --socks-addr "127.0.0.1" \
  --socks-port "1080"
```

### Force Update

Force update even if IP address hasn't changed:

```bash
./cloudflare-ddns.sh \
  --cloudflare-api-token "your-cloudflare-api-token" \
  --cloudflare-user-mail "your-email@example.com" \
  --cloudflare-zone-name "example.com" \
  --cloudflare-record-names "ddns.example.com" \
  --cloudflare-record-types "4" \
  --force-update
```
