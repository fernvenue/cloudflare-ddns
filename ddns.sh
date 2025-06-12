#!/bin/bash


set -o errexit
set -o nounset
set -o pipefail

CLOUDFLARE_API_TOKEN=
CLOUDFLARE_API_KEY=
CLOUDFLARE_RECORD_NAME=
CLOUDFLARE_RECORD_TYPE=
CLOUDFLARE_USER_MAIL=
CLOUDFLARE_ZONE_NAME=
OUTBOUND_INTERFACE=
SOCKS_ADDR=
SOCKS_PORT=
TELEGRAM_BOT_ID=
TELEGRAM_CHAT_ID=
FORCE_UPDATE=false

while getopts k:n:t:u:z:i:a:p:b:c:fr: opts; do
	case ${opts} in
		t) CLOUDFLARE_API_TOKEN=${OPTARG} ;;
		k) CLOUDFLARE_API_KEY=${OPTARG} ;;
		n) CLOUDFLARE_RECORD_NAME=${OPTARG} ;;
		r) CLOUDFLARE_RECORD_TYPE=${OPTARG} ;;
		u) CLOUDFLARE_USER_MAIL=${OPTARG} ;;
		z) CLOUDFLARE_ZONE_NAME=${OPTARG} ;;
		i) OUTBOUND_INTERFACE=${OPTARG} ;;
		a) SOCKS_ADDR=${OPTARG} ;;
		p) SOCKS_PORT=${OPTARG} ;;
		b) TELEGRAM_BOT_ID=${OPTARG} ;;
		c) TELEGRAM_CHAT_ID=${OPTARG} ;;
		f) FORCE_UPDATE=true ;;
		*);;
	esac
done

if [ "$CLOUDFLARE_API_TOKEN" = "" ] && [ "$CLOUDFLARE_API_KEY" = "" ]; then
    LOG_TIME=`date --rfc-3339 sec`
    printf "$LOG_TIME: CLOUDFLARE_API_TOKEN or CLOUDFLARE_API_KEY is required.\n"
    exit 2
fi

if [ "$CLOUDFLARE_API_TOKEN" != "" ] && [ "$CLOUDFLARE_API_KEY" != "" ]; then
    LOG_TIME=`date --rfc-3339 sec`
    printf "$LOG_TIME: CLOUDFLARE_API_TOKEN and CLOUDFLARE_API_KEY both set, CLOUDFLARE_API_KEY will be ignored.\n"
fi

if [ "$CLOUDFLARE_RECORD_NAME" = "" ]; then
	LOG_TIME=`date --rfc-3339 sec`
	printf "$LOG_TIME: CLOUDFLARE_RECORD_NAME is required.\n"
	exit 2
fi

PRIMARY_IP_API="https://icanhazip.com"
BACKUP_IP_API="https://ifconfig.me"

if [ "$CLOUDFLARE_RECORD_TYPE" = "A" ]; then
    IP_VERSION="-4"
elif [ "$CLOUDFLARE_RECORD_TYPE" = "AAAA" ]; then
    IP_VERSION="-6"
else
    LOG_TIME=`date --rfc-3339 sec`
    printf "$LOG_TIME: Invalid record type, CLOUDFLARE_RECORD_TYPE can only be A or AAAA.\n"
    exit 2
fi

if [ "$CLOUDFLARE_USER_MAIL" = "" ]; then
	LOG_TIME=`date --rfc-3339 sec`
	printf "$LOG_TIME: CLOUDFLARE_USER_MAIL is required.\n"
	exit 2
fi

if [ "$CLOUDFLARE_ZONE_NAME" = "" ]; then
	LOG_TIME=`date --rfc-3339 sec`
	printf "$LOG_TIME: CLOUDFLARE_ZONE_NAME is required.\n"
	exit 2
fi

if [ "$OUTBOUND_INTERFACE" != "" ]; then
	CURL_INTERFACE="--interface $OUTBOUND_INTERFACE"
else
	CURL_INTERFACE=""
fi

if [ "$SOCKS_ADDR" != "" ]; then
	if [ "$SOCKS_PORT" != "" ] && [ "$SOCKS_PORT" -gt 0 ] && [ "$SOCKS_PORT" -lt 65536 ]; then
		CURL_PROXY="-x socks5h://$SOCKS_ADDR:$SOCKS_PORT"
	else
		LOG_TIME=`date --rfc-3339 sec`
		printf "$LOG_TIME: Invalid socks server prot, it must be in 1-65535."
	fi
else
	CURL_PROXY=""
fi

# Try to get IP using primary service
PUBLIC_IP=`curl $IP_VERSION $CURL_INTERFACE $CURL_PROXY -s $PRIMARY_IP_API`
# If primary service failed (empty result), try backup service
if [ -z "$PUBLIC_IP" ]; then
    LOG_TIME=`date --rfc-3339 sec`
    printf "$LOG_TIME: Primary IP service failed, trying backup service...\n"
    PUBLIC_IP=`curl $IP_VERSION $CURL_INTERFACE $CURL_PROXY -s $BACKUP_IP_API`
    
    if [ -z "$PUBLIC_IP" ]; then
        LOG_TIME=`date --rfc-3339 sec`
        printf "$LOG_TIME: Failed to get public IP address from both services.\n"
        exit 1
    fi
fi

PUBLIC_IP_FILE=$HOME/.IP::$CLOUDFLARE_RECORD_TYPE::$CLOUDFLARE_RECORD_NAME.ddns

if [ -f $PUBLIC_IP_FILE ]; then
	OLD_PUBLIC_IP=`cat $PUBLIC_IP_FILE`
else
	OLD_PUBLIC_IP=""
fi

if [ "$PUBLIC_IP" = "$OLD_PUBLIC_IP" ] && [ "$FORCE_UPDATE" = false ]; then
	LOG_TIME=`date --rfc-3339 sec`
	printf "$LOG_TIME: Public IP not changed, you can use -f to update anyway.\n"
	exit 0
fi

CLOUDFLARE_ID_FILE=$HOME/.ID::$CLOUDFLARE_RECORD_TYPE::$CLOUDFLARE_RECORD_NAME.ddns

if [ -f $CLOUDFLARE_ID_FILE ] && [ $(wc -l $CLOUDFLARE_ID_FILE | cut -d " " -f 1) == 4 ] \
	&& [ "$(sed -n '3,1p' "$CLOUDFLARE_ID_FILE")" == "$CLOUDFLARE_ZONE_NAME" ] \
	&& [ "$(sed -n '4,1p' "$CLOUDFLARE_ID_FILE")" == "$CLOUDFLARE_RECORD_NAME" ]; then
		CLOUDFLARE_ZONE_ID=$(sed -n '1,1p' "$CLOUDFLARE_ID_FILE")
		CLOUDFLARE_RECORD_ID=$(sed -n '2,1p' "$CLOUDFLARE_ID_FILE")
else
    if [ "$CLOUDFLARE_API_TOKEN" != "" ]; then
        CLOUDFLARE_API_KEY=$CLOUDFLARE_API_TOKEN
            CLOUDFLARE_ZONE_ID=$(curl $CURL_INTERFACE $CURL_PROXY -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$CLOUDFLARE_ZONE_NAME" -H "X-Auth-Email: $CLOUDFLARE_USER_MAIL" -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
        CLOUDFLARE_RECORD_ID=$(curl $CURL_INTERFACE $CURL_PROXY -s -X GET "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records?name=$CLOUDFLARE_RECORD_NAME&type=$CLOUDFLARE_RECORD_TYPE" -H "X-Auth-Email: $CLOUDFLARE_USER_MAIL" -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*' | head -1 )
            printf "$CLOUDFLARE_ZONE_ID\n" > $CLOUDFLARE_ID_FILE
            printf "$CLOUDFLARE_RECORD_ID\n" >> $CLOUDFLARE_ID_FILE
            printf "$CLOUDFLARE_ZONE_NAME\n" >> $CLOUDFLARE_ID_FILE
            printf "$CLOUDFLARE_RECORD_NAME" >> $CLOUDFLARE_ID_FILE
    else
        CLOUDFLARE_API_KEY=$CLOUDFLARE_API_TOKEN
            CLOUDFLARE_ZONE_ID=$(curl $CURL_INTERFACE $CURL_PROXY -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$CLOUDFLARE_ZONE_NAME" -H "X-Auth-Email: $CLOUDFLARE_USER_MAIL" -H "X-Auth-Key: $CLOUDFLARE_API_KEY" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
        CLOUDFLARE_RECORD_ID=$(curl $CURL_INTERFACE $CURL_PROXY -s -X GET "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records?name=$CLOUDFLARE_RECORD_NAME&type=$CLOUDFLARE_RECORD_TYPE" -H "X-Auth-Email: $CLOUDFLARE_USER_MAIL" -H "X-Auth-Key: $CLOUDFLARE_API_KEY" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*' | head -1 )
            printf "$CLOUDFLARE_ZONE_ID\n" > $CLOUDFLARE_ID_FILE
            printf "$CLOUDFLARE_RECORD_ID\n" >> $CLOUDFLARE_ID_FILE
            printf "$CLOUDFLARE_ZONE_NAME\n" >> $CLOUDFLARE_ID_FILE
            printf "$CLOUDFLARE_RECORD_NAME" >> $CLOUDFLARE_ID_FILE
    fi
fi

LOG_TIME=`date --rfc-3339 sec`
printf "$LOG_TIME: Updating $CLOUDFLARE_RECORD_NAME to $PUBLIC_IP...\n"

if [ "$CLOUDFLARE_API_TOKEN" != "" ]; then
    CLOUDFLARE_API_RESPONSE=$(curl $CURL_INTERFACE $CURL_PROXY -o /dev/null -s -w "%{http_code}\n" -X PUT "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/$CLOUDFLARE_RECORD_ID" \
		-H "X-Auth-Email: $CLOUDFLARE_USER_MAIL" \
		-H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
		-H "Content-Type: application/json" \
		--data "{\"type\":\"$CLOUDFLARE_RECORD_TYPE\",\"name\":\"$CLOUDFLARE_RECORD_NAME\",\"content\":\"$PUBLIC_IP\", \"ttl\":120}")
else
    CLOUDFLARE_API_RESPONSE=$(curl $CURL_INTERFACE $CURL_PROXY -o /dev/null -s -w "%{http_code}\n" -X PUT "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/$CLOUDFLARE_RECORD_ID" \
		-H "X-Auth-Email: $CLOUDFLARE_USER_MAIL" \
		-H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
		-H "Content-Type: application/json" \
		--data "{\"type\":\"$CLOUDFLARE_RECORD_TYPE\",\"name\":\"$CLOUDFLARE_RECORD_NAME\",\"content\":\"$PUBLIC_IP\", \"ttl\":120}")
fi

if [ "$CLOUDFLARE_API_RESPONSE" != 200 ]; then
	LOG_TIME=`date --rfc-3339 sec`
	printf "$LOG_TIME: Failed to update record.\n"
	exit 1
else
	LOG_TIME=`date --rfc-3339 sec`
	printf "$LOG_TIME: $CLOUDFLARE_RECORD_NAME successfully updated to $PUBLIC_IP.\n"
	printf $PUBLIC_IP > $PUBLIC_IP_FILE
	if [ "$TELEGRAM_BOT_ID" != "" ]; then
		LOG_TIME=`date --rfc-3339 sec`
		printf "$LOG_TIME: Reporting to Telegram...\n"
		TELEGRAM_API_RESPONSE=`curl $CURL_INTERFACE $CURL_PROXY -o /dev/null -s -w "%{http_code}\n" "https://api.telegram.org/bot$TELEGRAM_BOT_ID/sendMessage?chat_id=$TELEGRAM_CHAT_ID&parse_mode=HTML&text=<b>DDNS%20Notification:</b>%0A$CLOUDFLARE_RECORD_TYPE%20type%20$CLOUDFLARE_RECORD_NAME%20successfully%20updated%20to%20$PUBLIC_IP"`
		if [ "$TELEGRAM_API_RESPONSE" != 200 ]; then
			LOG_TIME=`date --rfc-3339 sec`
			printf "$LOG_TIME: Report failed.\n"
			exit 2
		else
			LOG_TIME=`date --rfc-3339 sec`
			printf "$LOG_TIME: Reported successfully.\n"
			exit 0
		fi
	else
		exit 0
	fi
fi
