# Cloudflare DDNS

[![cloudflare-ddns](https://img.shields.io/badge/LICENSE-BSD3%20Clause%20Liscense-blue?style=flat-square)](./LICENSE)
[![cloudflare-ddns](https://img.shields.io/badge/GitHub-Cloudflare%20DDNS-blueviolet?style=flat-square&logo=github)](https://github.com/fernvenue/cloudflare-ddns)

A lightweight Cloudflare Dynamic DNS shell script.

## Features

### DNS Record Management
- [x] Support A (IPv4) and AAAA (IPv6) record types;
- [x] Update multiple DNS records simultaneously with batch processing;
- [x] Support comma-separated record names for bulk operations;
- [x] Flexible record type specification (4 for A, 6 for AAAA) with one-to-one mapping;
- [x] Intelligent IP change detection to avoid unnecessary updates;
- [x] Force update option to override IP change detection;
- [x] Automatic DNS record and zone ID caching for improved performance;

### Authentication & Security
- [x] Support for Cloudflare API tokens (recommended) and legacy global API keys;
- [x] Secure credential management through environment variables or command-line options;
- [x] SOCKS proxy support for both Cloudflare and Telegram APIs;
- [x] Network interface binding for multi-homed systems;

### Systemd Integration
- [x] Complete systemd service and timer configuration;
- [x] Dynamic user support for enhanced security isolation;
- [x] Automatic service restart on failure;
- [x] State directory management with proper permissions;
- [x] Configurable timer intervals with randomized delays;
- [x] Network dependency handling (waits for network-online.target);

### Monitoring & Notifications
- [x] Rich Telegram notifications with HTML formatting;
- [x] Detailed logging with RFC-3339 timestamps;
- [x] Fallback IP detection services for reliability;
- [x] Comprehensive error handling and status reporting;
- [x] Backup API service support when primary fails;

### Advanced Configuration
- [x] Specific outbound network interface selection;
- [x] Configurable working directory with fallback options;
- [x] Legacy configuration file migration support;
- [x] Command-line interface with comprehensive help system;
- [x] Environment variable and CLI parameter override support;

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
- `FORCE_UPDATE`: Used to update anyway even if the IP unchanged, default is `false`.

You can also define parameters by command line options:

- `--CLOUDFLARE_API_TOKEN TOKEN` = `$CLOUDFLARE_API_TOKEN`
- `--CLOUDFLARE_API_KEY KEY` = `$CLOUDFLARE_API_KEY`
- `--CLOUDFLARE_RECORD_NAMES NAMES` = `$CLOUDFLARE_RECORD_NAMES`
- `--CLOUDFLARE_RECORD_TYPES TYPES` = `$CLOUDFLARE_RECORD_TYPES`
- `--CLOUDFLARE_USER_MAIL EMAIL` = `$CLOUDFLARE_USER_MAIL`
- `--CLOUDFLARE_ZONE_NAME NAME` = `$CLOUDFLARE_ZONE_NAME`
- `--OUTBOUND_INTERFACE IFACE` = `$OUTBOUND_INTERFACE`
- `--SOCKS_ADDR ADDR` = `$SOCKS_ADDR`
- `--SOCKS_PORT PORT` = `$SOCKS_PORT`
- `--TELEGRAM_BOT_ID ID` = `$TELEGRAM_BOT_ID`
- `--TELEGRAM_CHAT_ID ID` = `$TELEGRAM_CHAT_ID`
- `--FORCE_UPDATE` = `$FORCE_UPDATE`

Give permission and run. **You must have resolved the target domain name to an address.**

For detailed help information, you can use:
```bash
./cloudflare-ddns.sh --help
```

We also provide systemd service and timer configuration files for automated execution, go check [`cloudflare-ddns.service`](./cloudflare-ddns.service) and [`cloudflare-ddns.timer`](./cloudflare-ddns.timer).

### System Dependencies
The script requires the following tools to be installed on your system:

- **bash** - Shell interpreter (usually pre-installed on most Linux distributions)
- **curl** - For making HTTP requests to Cloudflare API and IP detection services
- **jq** - For JSON parsing and manipulation of configuration files
- **awk** - For text processing (usually pre-installed)
- **grep** - For pattern matching (usually pre-installed)
- **date** - For timestamp generation (usually pre-installed)

## Examples

### Single DNS Record Update (IPv4 only)

Update a single A record with API token:

```bash
./cloudflare-ddns.sh \
  --CLOUDFLARE_API_TOKEN "your-cloudflare-api-token" \
  --CLOUDFLARE_USER_MAIL "your-email@example.com" \
  --CLOUDFLARE_ZONE_NAME "example.com" \
  --CLOUDFLARE_RECORD_NAMES "ddns.example.com" \
  --CLOUDFLARE_RECORD_TYPES "4"
```

### Single DNS Record Update (IPv6 only)

Update records with AAAA records only:

```bash
./cloudflare-ddns.sh \
  --CLOUDFLARE_API_TOKEN "your-cloudflare-api-token" \
  --CLOUDFLARE_USER_MAIL "your-email@example.com" \
  --CLOUDFLARE_ZONE_NAME "example.com" \
  --CLOUDFLARE_RECORD_NAMES "ipv6.example.com" \
  --CLOUDFLARE_RECORD_TYPES "6"
```

### Single Domain with Both IPv4 and IPv6

Update both A and AAAA records for the same domain (note the repeated domain name):

```bash
./cloudflare-ddns.sh \
  --CLOUDFLARE_API_TOKEN "your-cloudflare-api-token" \
  --CLOUDFLARE_USER_MAIL "your-email@example.com" \
  --CLOUDFLARE_ZONE_NAME "example.com" \
  --CLOUDFLARE_RECORD_NAMES "ddns.example.com,ddns.example.com" \
  --CLOUDFLARE_RECORD_TYPES "4,6"
```

In this example:
- First `ddns.example.com` gets A record (IPv4)
- Second `ddns.example.com` gets AAAA record (IPv6)

### Multiple DNS Records Update (Same Type)

Update multiple records with the same type (IPv4 only):

```bash
./cloudflare-ddns.sh \
  --CLOUDFLARE_API_TOKEN "your-cloudflare-api-token" \
  --CLOUDFLARE_USER_MAIL "your-email@example.com" \
  --CLOUDFLARE_ZONE_NAME "example.com" \
  --CLOUDFLARE_RECORD_NAMES "ddns.example.com,api.example.com,home.example.com" \
  --CLOUDFLARE_RECORD_TYPES "4,4,4"
```

### Multiple DNS Records with Different Types (One-to-One Mapping)

Update different records with different types (each record name corresponds to each record type):

```bash
./cloudflare-ddns.sh \
  --CLOUDFLARE_API_TOKEN "your-cloudflare-api-token" \
  --CLOUDFLARE_USER_MAIL "your-email@example.com" \
  --CLOUDFLARE_ZONE_NAME "example.com" \
  --CLOUDFLARE_RECORD_NAMES "api.example.com,ipv6.example.com,home.example.com" \
  --CLOUDFLARE_RECORD_TYPES "4,6,4"
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
  --CLOUDFLARE_API_TOKEN "your-cloudflare-api-token" \
  --CLOUDFLARE_USER_MAIL "your-email@example.com" \
  --CLOUDFLARE_ZONE_NAME "example.com" \
  --CLOUDFLARE_RECORD_NAMES "ddns.example.com" \
  --CLOUDFLARE_RECORD_TYPES "4" \
  --TELEGRAM_BOT_ID "123456789:ABCdefGHIjklMNOpqrsTUVwxyz" \
  --TELEGRAM_CHAT_ID "-1001234567890"
```

### With SOCKS Proxy

Use SOCKS proxy for API requests:

```bash
./cloudflare-ddns.sh \
  --CLOUDFLARE_API_TOKEN "your-cloudflare-api-token" \
  --CLOUDFLARE_USER_MAIL "your-email@example.com" \
  --CLOUDFLARE_ZONE_NAME "example.com" \
  --CLOUDFLARE_RECORD_NAMES "ddns.example.com" \
  --CLOUDFLARE_RECORD_TYPES "4" \
  --SOCKS_ADDR "127.0.0.1" \
  --SOCKS_PORT "1080"
```

### Force Update

Force update even if IP address hasn't changed:

```bash
./cloudflare-ddns.sh \
  --CLOUDFLARE_API_TOKEN "your-cloudflare-api-token" \
  --CLOUDFLARE_USER_MAIL "your-email@example.com" \
  --CLOUDFLARE_ZONE_NAME "example.com" \
  --CLOUDFLARE_RECORD_NAMES "ddns.example.com" \
  --CLOUDFLARE_RECORD_TYPES "4" \
  --FORCE_UPDATE
```
