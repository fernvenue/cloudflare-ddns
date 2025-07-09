#!/bin/bash
# Cloudflare Dynamic DNS Update Script;
# This script automatically updates DNS records in Cloudflare when the public IP changes;

set -o errexit
set -o nounset
set -o pipefail

# Logging function with timestamp;
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date --rfc-3339=seconds)
    printf "%s [%s]: %s\n" "$timestamp" "$level" "$message"
}

# Convenience logging functions;
log_info() {
    log "INFO" "$@"
}

log_error() {
    log "ERROR" "$@"
}

log_warning() {
    log "WARNING" "$@"
}

# Function to validate required parameter;
validate_required_param() {
    local param_name="$1"
    local param_value="$2"
    
    if [ "$param_value" = "" ]; then
        log_error "$param_name is required."
        exit 2
    fi
}

# Function to get public IP address for a specific IP version;
get_public_ip() {
    local ip_version="$1"
    local public_ip
    
    public_ip=$(curl $ip_version $CURL_INTERFACE $CURL_PROXY -s $PRIMARY_IP_API | awk -F= '/^ip/ {print $2}')
    
    if [ -z "$public_ip" ]; then
        log_warning "Primary IP service failed for IPv${ip_version#-}, trying backup service..."
        public_ip=$(curl $ip_version $CURL_INTERFACE $CURL_PROXY -s $BACKUP_IP_API | awk -F= '/^ip/ {print $2}')
        
        if [ -z "$public_ip" ]; then
            log_error "Failed to get public IPv${ip_version#-} address from all services."
            exit 1
        fi
        
        echo "$public_ip backup"
    else
        echo "$public_ip primary"
    fi
}

# Function to update config file with JSON data;
update_config_json() {
    local jq_expression="$1"
    local temp_json
    
    temp_json=$(jq "$jq_expression" "$CONFIG_FILE")
    echo "$temp_json" > "$CONFIG_FILE"
}

# Function to log DNS update to CSV file;
log_to_csv() {
    local zone_name="$1"
    local record_name="$2"
    local record_type="$3"
    local old_ip="$4"
    local new_ip="$5"
    local timestamp="$6"
    local used_backup="$7"
    
    # Skip CSV logging if disabled;
    if [ "$ENABLE_CSV_LOG" != "true" ]; then
        return 0
    fi
    
    local csv_file="$WORK_DIR/history.csv"
    
    # Create CSV file with headers if it doesn't exist;
    if [ ! -f "$csv_file" ]; then
        echo "Timestamp,Zone Name,Record Name,Record Type,Old IP,New IP,Backup API Used" > "$csv_file"
    fi
    
    # Append new record to CSV;
    echo "$timestamp,$zone_name,$record_name,$record_type,$old_ip,$new_ip,$used_backup" >> "$csv_file"
    
    log_info "DNS update logged to CSV: $zone_name/$record_name ($record_type) $old_ip -> $new_ip"
}

# Environment variables and their defaults;
CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN:-}
CLOUDFLARE_API_KEY=${CLOUDFLARE_API_KEY:-}
CLOUDFLARE_RECORD_NAMES=${CLOUDFLARE_RECORD_NAMES:-}
CLOUDFLARE_RECORD_TYPES=${CLOUDFLARE_RECORD_TYPES:-}
CLOUDFLARE_USER_MAIL=${CLOUDFLARE_USER_MAIL:-}
CLOUDFLARE_ZONE_NAME=${CLOUDFLARE_ZONE_NAME:-}
OUTBOUND_INTERFACE=${OUTBOUND_INTERFACE:-}
SOCKS_ADDR=${SOCKS_ADDR:-}
SOCKS_PORT=${SOCKS_PORT:-}
TELEGRAM_BOT_ID=${TELEGRAM_BOT_ID:-}
TELEGRAM_CHAT_ID=${TELEGRAM_CHAT_ID:-}
CUSTOM_TELEGRAM_ENDPOINT=${CUSTOM_TELEGRAM_ENDPOINT:-}
PRIMARY_IP_API=${PRIMARY_IP_API:-}
BACKUP_IP_API=${BACKUP_IP_API:-}
ENABLE_CSV_LOG=${ENABLE_CSV_LOG:-true}
FORCE_UPDATE=false

# Parse command line arguments;
while [[ $# -gt 0 ]]; do
	case $1 in
		--cloudflare-api-token)
			CLOUDFLARE_API_TOKEN="$2"
			shift 2
			;;
		--cloudflare-api-key)
			CLOUDFLARE_API_KEY="$2"
			shift 2
			;;
		--cloudflare-record-names)
			CLOUDFLARE_RECORD_NAMES="$2"
			shift 2
			;;
		--cloudflare-record-types)
			CLOUDFLARE_RECORD_TYPES="$2"
			shift 2
			;;
		--cloudflare-user-mail)
			CLOUDFLARE_USER_MAIL="$2"
			shift 2
			;;
		--cloudflare-zone-name)
			CLOUDFLARE_ZONE_NAME="$2"
			shift 2
			;;
		--outbound-interface)
			OUTBOUND_INTERFACE="$2"
			shift 2
			;;
		--socks-addr)
			SOCKS_ADDR="$2"
			shift 2
			;;
		--socks-port)
			SOCKS_PORT="$2"
			shift 2
			;;
		--telegram-bot-id)
			TELEGRAM_BOT_ID="$2"
			shift 2
			;;
		--telegram-chat-id)
			TELEGRAM_CHAT_ID="$2"
			shift 2
			;;
		--custom-telegram-endpoint)
			CUSTOM_TELEGRAM_ENDPOINT="$2"
			shift 2
			;;
		--primary-ip-api)
			PRIMARY_IP_API="$2"
			shift 2
			;;
		--backup-ip-api)
			BACKUP_IP_API="$2"
			shift 2
			;;
		--force-update)
			FORCE_UPDATE=true
			shift
			;;
		--enable-csv-log)
			ENABLE_CSV_LOG="$2"
			shift 2
			;;
		-h|--help)
			echo "Usage: $0 [OPTIONS]"
			echo "Options:"
			echo "  --cloudflare-api-token TOKEN        Cloudflare API token"
			echo "  --cloudflare-api-key KEY            Cloudflare API key (legacy)"
			echo "  --cloudflare-record-names NAMES     Comma-separated DNS record names (e.g., 'www.example.com,api.example.com')"
			echo "  --cloudflare-record-types TYPES     Comma-separated DNS record types (4 for A, 6 for AAAA) corresponding one-to-one with record names"
			echo "  --cloudflare-user-mail EMAIL        Cloudflare user email"
			echo "  --cloudflare-zone-name NAME         Cloudflare zone name"
			echo "  --outbound-interface IFACE          Outbound network interface"
			echo "  --socks-addr ADDR                   SOCKS proxy address"
			echo "  --socks-port PORT                   SOCKS proxy port"
			echo "  --telegram-bot-id ID                Telegram bot ID for notifications"
			echo "  --telegram-chat-id ID               Telegram chat ID for notifications"
			echo "  --custom-telegram-endpoint DOMAIN   Custom Telegram API domain (default: api.telegram.org)"
			echo "  --force-update                      Force update even if IP hasn't changed"
			echo "  --enable-csv-log BOOL               Enable CSV logging (true/false, default: true)"
			echo "  -h, --help                          Show this help message"
			exit 0
			;;
		*)
			echo "Unknown option: $1"
			echo "Use --help for usage information"
			exit 1
			;;
	esac
done

# Validate required parameters;
if [ "$CLOUDFLARE_API_TOKEN" = "" ] && [ "$CLOUDFLARE_API_KEY" = "" ]; then
    log_error "CLOUDFLARE_API_TOKEN or CLOUDFLARE_API_KEY is required."
    exit 2
fi

if [ "$CLOUDFLARE_API_TOKEN" != "" ] && [ "$CLOUDFLARE_API_KEY" != "" ]; then
    log_warning "CLOUDFLARE_API_TOKEN and CLOUDFLARE_API_KEY both set, CLOUDFLARE_API_KEY will be ignored."
fi

validate_required_param "CLOUDFLARE_RECORD_NAMES" "$CLOUDFLARE_RECORD_NAMES"
validate_required_param "CLOUDFLARE_RECORD_TYPES" "$CLOUDFLARE_RECORD_TYPES"

# Validate that the number of record names matches the number of record types;
IFS=',' read -ra RECORD_NAMES_ARRAY <<< "$CLOUDFLARE_RECORD_NAMES"
IFS=',' read -ra RECORD_TYPES_ARRAY <<< "$CLOUDFLARE_RECORD_TYPES"

if [ ${#RECORD_NAMES_ARRAY[@]} -ne ${#RECORD_TYPES_ARRAY[@]} ]; then
	log_error "Number of record names (${#RECORD_NAMES_ARRAY[@]}) must match number of record types (${#RECORD_TYPES_ARRAY[@]})."
	exit 2
fi

# IP service endpoints for retrieving public IP addresses;
PRIMARY_IP_API=${PRIMARY_IP_API:-"https://icanhazip.com/cdn-cgi/trace"}
BACKUP_IP_API=${BACKUP_IP_API:-"https://api.cloudflare.com/cdn-cgi/trace"}

# Parse and validate record types (4=IPv4, 6=IPv6);
# Record types must correspond one-to-one with record names;
IFS=',' read -ra USER_TYPES <<< "$CLOUDFLARE_RECORD_TYPES"
declare -A SEEN_GLOBAL_TYPES
declare -a RECORD_TYPE_MAPPINGS

# Validate each record type and build mapping array;
for user_type in "${USER_TYPES[@]}"; do
    user_type=$(echo "$user_type" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ "$user_type" = "4" ]; then
        RECORD_TYPE_MAPPINGS+=("4")
        SEEN_GLOBAL_TYPES["A"]=1
    elif [ "$user_type" = "6" ]; then
        RECORD_TYPE_MAPPINGS+=("6")
        SEEN_GLOBAL_TYPES["AAAA"]=1
    else
        log_error "Invalid record type '$user_type', supported types are: 4, 6."
        exit 2
    fi
done

# Build IP version flags based on all record types needed;
IP_VERSIONS=()
if [ -n "${SEEN_GLOBAL_TYPES["A"]:-}" ]; then
    IP_VERSIONS+=("-4")
fi
if [ -n "${SEEN_GLOBAL_TYPES["AAAA"]:-}" ]; then
    IP_VERSIONS+=("-6")
fi

validate_required_param "CLOUDFLARE_USER_MAIL" "$CLOUDFLARE_USER_MAIL"
validate_required_param "CLOUDFLARE_ZONE_NAME" "$CLOUDFLARE_ZONE_NAME"

# Configure network interface for curl if specified;
if [ "$OUTBOUND_INTERFACE" != "" ]; then
	CURL_INTERFACE="--interface $OUTBOUND_INTERFACE"
else
	CURL_INTERFACE=""
fi

# Configure SOCKS proxy for curl if specified;
if [ "$SOCKS_ADDR" != "" ]; then
	if [ "$SOCKS_PORT" != "" ] && [ "$SOCKS_PORT" -gt 0 ] && [ "$SOCKS_PORT" -lt 65536 ]; then
		CURL_PROXY="-x socks5h://$SOCKS_ADDR:$SOCKS_PORT"
	else
		log_error "Invalid socks server port, it must be in 1-65535."
		exit 2
	fi
else
	CURL_PROXY=""
fi

# Get public IP addresses for each IP version;
declare -A PUBLIC_IPS
declare -A USED_BACKUP_APIS

for ip_version in "${IP_VERSIONS[@]}"; do
    ip_result=$(get_public_ip "$ip_version")
    public_ip=$(echo "$ip_result" | cut -d' ' -f1)
    source_type=$(echo "$ip_result" | cut -d' ' -f2)
    
    PUBLIC_IPS["$ip_version"]="$public_ip"
    USED_BACKUP_APIS["$ip_version"]=$([ "$source_type" = "backup" ] && echo "true" || echo "false")
    
    log_info "Got public IPv${ip_version#-} address: $public_ip"
done

# Determine working directory for storing state data;
if [ -n "${STATE_DIRECTORY:-}" ]; then
    WORK_DIR="$STATE_DIRECTORY"
elif [ -w "/var/lib" ] 2>/dev/null; then
    WORK_DIR="/var/lib/cloudflare-ddns"
    mkdir -p "$WORK_DIR" 2>/dev/null || WORK_DIR=""
else
    WORK_DIR=""
fi

if [ "$WORK_DIR" = "" ] && [ "${HOME:-}" != "" ]; then
    WORK_DIR="$HOME/.cache/cloudflare-ddns"
    mkdir -p "$WORK_DIR" 2>/dev/null || WORK_DIR=""
fi

if [ "$WORK_DIR" = "" ]; then
    WORK_DIR="/tmp/cloudflare-ddns"
    mkdir -p "$WORK_DIR" 2>/dev/null || {
        log_error "Failed to create working directory, exiting."
        exit 1
    }
    log_warning "Using /tmp/cloudflare-ddns, files may be lost on reboot."
fi

# Function to update a single DNS record;
update_dns_record() {
    local RECORD_NAME="$1"
    local RECORD_TYPE="$2"
    local PUBLIC_IP="$3"
    local OLD_IP="$4"
    local USED_BACKUP="$5"
    
    log_info "Processing $RECORD_TYPE record $RECORD_NAME..."
    
    local CLOUDFLARE_ZONE_ID=$(jq -r ".\"$CLOUDFLARE_ZONE_NAME\".zone_id // \"\"" "$CONFIG_FILE" 2>/dev/null || echo "")
    local CLOUDFLARE_RECORD_ID=$(jq -r ".\"$CLOUDFLARE_ZONE_NAME\".records.\"$RECORD_NAME\".\"$RECORD_TYPE\".record_id // \"\"" "$CONFIG_FILE" 2>/dev/null || echo "")

    # Fetch zone and record IDs if not cached;
    if [ "$CLOUDFLARE_ZONE_ID" = "" ] || [ "$CLOUDFLARE_RECORD_ID" = "" ]; then
        log_info "Fetching zone and record IDs for $RECORD_TYPE $RECORD_NAME..."
        
        # Use API token or legacy API key for authentication;
        if [ "$CLOUDFLARE_API_TOKEN" != "" ]; then
            CLOUDFLARE_ZONE_ID=$(curl $CURL_INTERFACE $CURL_PROXY -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$CLOUDFLARE_ZONE_NAME" -H "X-Auth-Email: $CLOUDFLARE_USER_MAIL" -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
            CLOUDFLARE_RECORD_ID=$(curl $CURL_INTERFACE $CURL_PROXY -s -X GET "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records?name=$RECORD_NAME&type=$RECORD_TYPE" -H "X-Auth-Email: $CLOUDFLARE_USER_MAIL" -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*' | head -1 )
        else
            CLOUDFLARE_ZONE_ID=$(curl $CURL_INTERFACE $CURL_PROXY -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$CLOUDFLARE_ZONE_NAME" -H "X-Auth-Email: $CLOUDFLARE_USER_MAIL" -H "X-Auth-Key: $CLOUDFLARE_API_KEY" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
            CLOUDFLARE_RECORD_ID=$(curl $CURL_INTERFACE $CURL_PROXY -s -X GET "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records?name=$RECORD_NAME&type=$RECORD_TYPE" -H "X-Auth-Email: $CLOUDFLARE_USER_MAIL" -H "X-Auth-Key: $CLOUDFLARE_API_KEY" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*' | head -1 )
        fi

        # Save the fetched IDs to config file;
        local OLD_IP=$(jq -r ".\"$CLOUDFLARE_ZONE_NAME\".records.\"$RECORD_NAME\".\"$RECORD_TYPE\".last_ip // \"\"" "$CONFIG_FILE" 2>/dev/null || echo "")
        update_config_json ".\"$CLOUDFLARE_ZONE_NAME\".zone_id = \"$CLOUDFLARE_ZONE_ID\" |
            .\"$CLOUDFLARE_ZONE_NAME\".records.\"$RECORD_NAME\".\"$RECORD_TYPE\" = {
                \"record_id\": \"$CLOUDFLARE_RECORD_ID\",
                \"last_ip\": \"$OLD_IP\",
                \"last_updated\": \"$(date --rfc-3339=seconds)\"
            }"
    fi

    log_info "Updating $RECORD_TYPE $RECORD_NAME to $PUBLIC_IP..."

    # Send API request to update DNS record;
    local CLOUDFLARE_API_RESPONSE
    if [ "$CLOUDFLARE_API_TOKEN" != "" ]; then
        CLOUDFLARE_API_RESPONSE=$(curl $CURL_INTERFACE $CURL_PROXY -o /dev/null -s -w "%{http_code}\n" -X PUT "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/$CLOUDFLARE_RECORD_ID" \
            -H "X-Auth-Email: $CLOUDFLARE_USER_MAIL" \
            -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"$RECORD_TYPE\",\"name\":\"$RECORD_NAME\",\"content\":\"$PUBLIC_IP\", \"ttl\":120}")
    else
        CLOUDFLARE_API_RESPONSE=$(curl $CURL_INTERFACE $CURL_PROXY -o /dev/null -s -w "%{http_code}\n" -X PUT "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/$CLOUDFLARE_RECORD_ID" \
            -H "X-Auth-Email: $CLOUDFLARE_USER_MAIL" \
            -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"$RECORD_TYPE\",\"name\":\"$RECORD_NAME\",\"content\":\"$PUBLIC_IP\", \"ttl\":120}")
    fi

    # Check API response and update local cache;
    if [[ "$CLOUDFLARE_API_RESPONSE" != 200 ]]; then
        log_error "Failed to update $RECORD_TYPE record $RECORD_NAME."
        return 1
    else
        log_info "$RECORD_TYPE $RECORD_NAME successfully updated to $PUBLIC_IP."

        # Update local cache with new IP and timestamp;
        local update_timestamp="$(date --rfc-3339=seconds)"
        update_config_json ".\"$CLOUDFLARE_ZONE_NAME\".records.\"$RECORD_NAME\".\"$RECORD_TYPE\".last_ip = \"$PUBLIC_IP\" |
            .\"$CLOUDFLARE_ZONE_NAME\".records.\"$RECORD_NAME\".\"$RECORD_TYPE\".last_updated = \"$update_timestamp\""
        
        # Log to CSV if enabled;
        log_to_csv "$CLOUDFLARE_ZONE_NAME" "$RECORD_NAME" "$RECORD_TYPE" "$OLD_IP" "$PUBLIC_IP" "$update_timestamp" "$USED_BACKUP"
        
        return 0
    fi
}

# Initialize config file and migrate from old formats if needed;
CONFIG_FILE="$WORK_DIR/data.json"

if [ ! -f "$CONFIG_FILE" ]; then
	echo '{}' > "$CONFIG_FILE"
fi

# Migrate config file from old formats to current format;
if jq -e '.zones' "$CONFIG_FILE" >/dev/null 2>&1; then
    log_info "Migrating config from zones wrapper format to direct format..."
    
    ZONES_DATA=$(jq -r '.zones' "$CONFIG_FILE" 2>/dev/null || echo "{}")
    echo "$ZONES_DATA" > "$CONFIG_FILE"
elif jq -e '.records' "$CONFIG_FILE" >/dev/null 2>&1; then
    log_info "Migrating config from records format to direct format..."
    
    OLD_RECORDS=$(jq -r '.records | to_entries | .[] | "\(.key) \(.value.zone_name) \(.value.record_name) \(.value.record_type) \(.value.record_id) \(.value.last_ip) \(.value.last_updated)"' "$CONFIG_FILE" 2>/dev/null || echo "")
    echo '{}' > "$CONFIG_FILE"
    
    if [ "$OLD_RECORDS" != "" ]; then
        while IFS=' ' read -r key zone_name record_name record_type record_id last_ip last_updated; do
            if [ "$key" != "" ] && [ "$zone_name" != "" ] && [ "$record_name" != "" ] && [ "$record_type" != "" ]; then
                update_config_json ".\"$zone_name\".zone_id = \"\" |
                    .\"$zone_name\".records.\"$record_name\".\"$record_type\" = {
                        \"record_id\": \"$record_id\",
                        \"last_ip\": \"$last_ip\",
                        \"last_updated\": \"$last_updated\"
                    }"
            fi
        done <<< "$OLD_RECORDS"
    fi
fi

# Parse record names and remove duplicates;
IFS=',' read -ra RECORD_NAMES_ARRAY <<< "$CLOUDFLARE_RECORD_NAMES"
UPDATED_RECORDS=""
FAILED_RECORDS=""

# Parse record names and remove empty entries but keep duplicates;
PROCESSED_RECORD_NAMES=()
for record_name in "${RECORD_NAMES_ARRAY[@]}"; do
    record_name=$(echo "$record_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ "$record_name" != "" ]; then
        PROCESSED_RECORD_NAMES+=("$record_name")
    fi
done

# Validate that number of record names matches number of record types;
if [ ${#PROCESSED_RECORD_NAMES[@]} -ne ${#RECORD_TYPE_MAPPINGS[@]} ]; then
    log_error "Number of record names (${#PROCESSED_RECORD_NAMES[@]}) does not match number of record types (${#RECORD_TYPE_MAPPINGS[@]})."
    log_error "Record names: ${PROCESSED_RECORD_NAMES[*]}"
    log_error "Record types: ${RECORD_TYPE_MAPPINGS[*]}"
    exit 2
fi

# Process each record name with its corresponding type;
for i in "${!PROCESSED_RECORD_NAMES[@]}"; do
    record_name="${PROCESSED_RECORD_NAMES[$i]}"
    record_type_mapping="${RECORD_TYPE_MAPPINGS[$i]}"
    
    # Determine which record type to create for this record name;
    if [ "$record_type_mapping" = "4" ]; then
        record_type="A"
        current_ip="${PUBLIC_IPS["-4"]}"
    elif [ "$record_type_mapping" = "6" ]; then
        record_type="AAAA"
        current_ip="${PUBLIC_IPS["-6"]}"
    else
        log_error "Invalid record type mapping '$record_type_mapping' for $record_name."
        continue
    fi
    
    OLD_PUBLIC_IP=$(jq -r ".\"$CLOUDFLARE_ZONE_NAME\".records.\"$record_name\".\"$record_type\".last_ip // \"\"" "$CONFIG_FILE" 2>/dev/null || echo "")
    
    # Determine if backup API was used for this IP version;
    used_backup="${USED_BACKUP_APIS[$([ "$record_type" = "A" ] && echo "-4" || echo "-6")]}"
    
    # Skip update if IP hasn't changed (unless forced);
    if [ "$current_ip" = "$OLD_PUBLIC_IP" ] && [ "$FORCE_UPDATE" = false ]; then
        log_info "$record_type $record_name IP not changed ($current_ip), skipping..."
    else
        if update_dns_record "$record_name" "$record_type" "$current_ip" "$OLD_PUBLIC_IP" "$used_backup"; then
            record_info="$record_type:$record_name"
            if [ "$UPDATED_RECORDS" = "" ]; then
                UPDATED_RECORDS="$record_info"
            else
                UPDATED_RECORDS="$UPDATED_RECORDS, $record_info"
            fi
        else
            record_info="$record_type:$record_name"
            if [ "$FAILED_RECORDS" = "" ]; then
                FAILED_RECORDS="$record_info"
            else
                FAILED_RECORDS="$FAILED_RECORDS, $record_info"
            fi
        fi
    fi
done

if [ "$FAILED_RECORDS" != "" ]; then
    log_error "Some records failed to update: $FAILED_RECORDS"
fi

if [ "$UPDATED_RECORDS" = "" ]; then
    log_info "No records were updated. Use --force to update anyway."
    exit 0
fi

# Function to send Telegram notification for DNS record updates;
send_telegram_notification() {
    local record_info="$1"
    local record_type=$(echo "$record_info" | cut -d':' -f1)
    local record_name=$(echo "$record_info" | cut -d':' -f2)
    
    local current_ip
    if [ "$record_type" = "A" ]; then
        current_ip="${PUBLIC_IPS["-4"]}"
        ip_type="IPv4"
    else
        current_ip="${PUBLIC_IPS["-6"]}"
        ip_type="IPv6"
    fi
    
    local used_backup="${USED_BACKUP_APIS[$([ "$record_type" = "A" ] && echo "-4" || echo "-6")]}"
    
    # Format Telegram message with HTML markup;
    local message_text="🔄 <b>DNS Record Updated</b>

📍 <b>Record:</b> <code>$record_name</code>
🏷️ <b>Type:</b> <code>$record_type</code> ($ip_type)
🌐 <b>New IP:</b> <code>$current_ip</code>
📅 <b>Time:</b> <code>$(date '+%Y-%m-%d %H:%M:%S %Z')</code>"
    
    if [ "$used_backup" = "true" ]; then
        message_text="$message_text

⚠️ <i>Note: Primary IP service failed, used backup service</i>"
    fi
    
    # Send Telegram message via Bot API;
    local telegram_payload=$(jq -n \
        --arg chat_id "$TELEGRAM_CHAT_ID" \
        --arg text "$message_text" \
        '{chat_id: $chat_id, parse_mode: "HTML", text: $text}')
    
    # Use custom endpoint if provided, otherwise use default;
    local telegram_api_url
    if [ "$CUSTOM_TELEGRAM_ENDPOINT" != "" ]; then
        telegram_api_url="https://${CUSTOM_TELEGRAM_ENDPOINT}/bot${TELEGRAM_BOT_ID}/sendMessage"
    else
        telegram_api_url="https://api.telegram.org/bot${TELEGRAM_BOT_ID}/sendMessage"
    fi
    
    local response=$(curl $CURL_INTERFACE $CURL_PROXY -s -o /dev/null -w "%{http_code}" \
        -X POST "$telegram_api_url" \
        -H "Content-Type: application/json" \
        -d "$telegram_payload")
    
    if [[ "$response" != 200 ]]; then
        log_error "Failed to send Telegram notification for $record_info (HTTP $response)."
        return 1
    else
        log_info "Telegram notification sent for $record_info."
        return 0
    fi
}

# Send Telegram notifications for all updated records;
if [[ "$TELEGRAM_BOT_ID" != "" ]] && [[ "$UPDATED_RECORDS" != "" ]]; then
    log_info "Sending Telegram notifications..."

    IFS=',' read -ra UPDATED_ARRAY <<< "$UPDATED_RECORDS"
    NOTIFICATION_FAILURES=0
    
    for record_info in "${UPDATED_ARRAY[@]}"; do
        record_info=$(echo "$record_info" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [ "$record_info" != "" ]; then
            if ! send_telegram_notification "$record_info"; then
                ((NOTIFICATION_FAILURES++))
            fi
        fi
    done
    
    if [ $NOTIFICATION_FAILURES -gt 0 ]; then
        log_error "$NOTIFICATION_FAILURES Telegram notification(s) failed."
    else
        log_info "All Telegram notifications sent successfully."
    fi
fi

# Exit with appropriate status code;
if [ "$FAILED_RECORDS" != "" ]; then
    exit 1
else
    exit 0
fi