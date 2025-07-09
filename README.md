# Cloudflare DDNS

[![cloudflare-ddns](https://img.shields.io/badge/LICENSE-BSD3%20Clause%20Liscense-blue?style=flat-square)](./LICENSE)
[![cloudflare-ddns](https://img.shields.io/badge/GitHub-Cloudflare%20DDNS-blueviolet?style=flat-square&logo=github)](https://github.com/fernvenue/cloudflare-ddns)

A lightweight Cloudflare Dynamic DNS shell script.

[中文說明](./README.zh.md)

## Features

- [x] **Dual Stack Support**: Support for both IPv4 and IPv6;
- [x] **Multi-Record Support**: Support for updating multiple records simultaneously;
- [x] **Smart Monitoring**: Only updates DNS records when IP address changes;
- [x] **Auto Caching**: Automatically caches DNS records and zone information for improved performance;
- [x] **Multiple Authentication Support**: Support for both Cloudflare API Token and Legacy API Key authentication;
- [x] **Proxy Protocol Support**: Support for configuring Socks proxy for API requests;
- [x] **Systemd Support**: Provides service/timer examples and dynamic user support;
- [x] **Telegram Push**: Highly readable Telegram notification push;
- [x] **CSV Logging**: Automatic logging of DNS updates to CSV file for history tracking and analysis;
- [x] **Flexible Configuration**: Support for command line parameter passing and environment variable configuration;

## Usage

Get the script:

```
curl -o /usr/local/bin/cloudflare-ddns.sh https://raw.githubusercontent.com/fernvenue/cloudflare-ddns/refs/heads/master/cloudflare-ddns.sh
vim /usr/local/bin/cloudflare-ddns.sh
```

Give it executable permission and run. **Make sure the corresponding domain already has records before running**, otherwise the script cannot find the records to update.

For detailed help information, you can use:

```bash
./cloudflare-ddns.sh --help
```

### Environment Variables

- `CLOUDFLARE_API_TOKEN`: API Token of your Cloudflare account (recommended);
- `CLOUDFLARE_API_KEY`: Global API Key of your Cloudflare account;
- `CLOUDFLARE_RECORD_NAMES`: Target record names, such as `ddns.example.com` or `ddns01.example.com,ddns02.example.com`;
- `CLOUDFLARE_RECORD_TYPES`: Record types, can be `4` (A) or `6` (AAAA), corresponds one-to-one with record names, such as `4,6,4`;
- `CLOUDFLARE_USER_MAIL`: The email address of your Cloudflare account;
- `CLOUDFLARE_ZONE_NAME`: Zone name, such as `example.com`;
- `OUTBOUND_INTERFACE`: Optional, used to specify the network interface;
- `SOCKS_ADDR`: Optional, used to configure Socks proxy for API requests (Cloudflare and Telegram), IP detection does not go through this proxy;
- `SOCKS_PORT`: Optional, corresponding Socks proxy port;
- `TELEGRAM_BOT_ID`: Optional, Telegram bot ID;
- `TELEGRAM_CHAT_ID`: Optional, Telegram target chat for push notifications;
- `CUSTOM_TELEGRAM_ENDPOINT`: Optional, used to customize the API domain used for Telegram push;
- `ENABLE_CSV_LOG`: Optional, enable CSV logging (default: `true`), set to `false` to disable;
- `FORCE_UPDATE`: Force update, update DNS records even if IP hasn't changed;

### Command Line Options

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
- `--enable-csv-log BOOL` = `$ENABLE_CSV_LOG`
- `--force-update` = `$FORCE_UPDATE`

### Systemd

Refer to [`cloudflare-ddns.service`](./cloudflare-ddns.service) and [`cloudflare-ddns.timer`](./cloudflare-ddns.timer) for standard systemd service and systemd timer examples.

### CSV Logging

The script automatically logs all DNS record updates to a CSV file for history tracking and analysis. This feature is enabled by default.

**CSV File Location**: The CSV file `history.csv` is created in the same directory as the configuration data:
- If `STATE_DIRECTORY` is set: `$STATE_DIRECTORY/history.csv`
- If `/var/lib` is writable: `/var/lib/cloudflare-ddns/history.csv`
- If `$HOME` is available: `$HOME/.cache/cloudflare-ddns/history.csv`
- Fallback: `/tmp/cloudflare-ddns/history.csv`

**CSV Format**: The CSV file contains the following columns:
- `Timestamp`: RFC3339 formatted timestamp of the update
- `Zone Name`: Cloudflare zone name (e.g., `example.com`)
- `Record Name`: DNS record name (e.g., `ddns.example.com`)
- `Record Type`: DNS record type (`A` or `AAAA`)
- `Old IP`: Previous IP address (empty for new records)
- `New IP`: New IP address after update
- `Backup API Used`: Whether backup IP detection service was used (`true`/`false`)

**Example CSV content**:
```csv
Timestamp,Zone Name,Record Name,Record Type,Old IP,New IP,Backup API Used
2025-07-09T10:30:45+08:00,example.com,ddns.example.com,A,192.168.1.100,203.0.113.42,false
2025-07-09T10:30:45+08:00,example.com,ddns.example.com,AAAA,,2001:db8::1,false
```

**Disable CSV Logging**: To disable CSV logging, set the environment variable `ENABLE_CSV_LOG=false` or use the command line option `--enable-csv-log false`.

### System Dependencies

The script requires the following tools to be installed on your system:

- **curl** - For sending HTTP requests to Cloudflare API and IP detection services;
- **jq** - For JSON parsing and configuration file operations;
- **awk** - For text processing (usually pre-installed);
- **grep** - For pattern matching (usually pre-installed);
- **date** - For timestamp generation (usually pre-installed);

## Examples

The following examples are some common use cases, for reference only. For production environment deployment, it is recommended to use with systemd service and systemd timer.

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

Update a single AAAA record with API token:

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

```bash
export CLOUDFLARE_API_TOKEN="your-cloudflare-api-token"
export CLOUDFLARE_USER_MAIL="your-email@example.com"
export CLOUDFLARE_ZONE_NAME="example.com"
export CLOUDFLARE_RECORD_NAMES="api.example.com,ipv6.example.com,home.example.com"
export CLOUDFLARE_RECORD_TYPES="4,6,4"

./cloudflare-ddns.sh
```

### With Telegram Notifications

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

Use custom Telegram API domain:

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
  --socks-addr "[::1]" \
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

### Disable CSV Logging

Disable CSV logging for DNS updates:

```bash
./cloudflare-ddns.sh \
  --cloudflare-api-token "your-cloudflare-api-token" \
  --cloudflare-user-mail "your-email@example.com" \
  --cloudflare-zone-name "example.com" \
  --cloudflare-record-names "ddns.example.com" \
  --cloudflare-record-types "4" \
  --enable-csv-log false
```
