#!/usr/bin/env bashio

declare EMAIL
declare TOKEN
declare ZONE
declare INTERVAL
declare SHOW_HIDE_PIP
declare ARR

EMAIL=$(bashio::config 'email_address' | xargs echo -n)
TOKEN=$(bashio::config 'cloudflare_api_token'| xargs echo -n)
ZONE=$(bashio::config 'cloudflare_zone_id'| xargs echo -n)
INTERVAL=$(bashio::config 'interval')
SHOW_HIDE_PIP=$(bashio::config 'hide_public_ip')
SORT=$(bashio::config 'sort')
CHECK_MARK="\033[0;32m\xE2\x9C\x94\033[0m"
CROSS_MARK="\u274c"

if [[ ${SORT} == true ]];
then
    ARR=$(for j in $(bashio::config "domains|keys"); do echo $(bashio::config "domains[${j}].domain"); done | sort -n)
else
    ARR=$(for j in $(bashio::config "domains|keys"); do echo $(bashio::config "domains[${j}].domain"); done)
fi

for ITEM in ${ARR[@]};
do
    echo -e "- ${ITEM}"
#    ARR+= $(bashio::config "domains[${ITEM}].domain")
done

echo -e ${ARR[@]}



echo -e $(bashio::config 'domains|keys' | awk 'NR==FNR{a[FNR]=$1;next} {print a[$1]}')

if ! [[ ${EMAIL} == ?*@?*.?* ]];
then
    echo -e "\e[1;31mFailed to run due to invalid email address\e[1;37m\n"
    exit 1
elif [[ ${#TOKEN} == 0 ]];
then
    echo -e "\e[1;31mFailed to run due to missing Cloudflare API token\e[1;37m\n"
    exit 1
elif [[ ${#ZONE} == 0 ]];
then
    echo -e "\e[1;31mFailed to run due to missing Cloudflare Zone ID\e[1;37m\n"
    exit 1
fi

if [[ ${INTERVAL} == 1 ]];
then
    echo -e "Checking A records every minute\n "
else
    echo -e "Checking A records every ${INTERVAL} minutes\n "
fi

check () {
    ERROR=0
    DOMAIN=$1
    DNS_RECORD=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records?type=A&name=${DOMAIN}&page=1&per_page=100&match=all" \
        -H "X-Auth-Email: ${EMAIL}" \
        -H "Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json")

    if [[ ${DNS_RECORD} == *"\"success\":false"* ]];
    then
        ERROR=$(echo ${DNS_RECORD} | awk '{ sub(/.*"message":"/, ""); sub(/".*/, ""); print }')
        echo -e " - ${DOMAIN} \e[1;31m${CROSS_MARK} ${ERROR}\e[1;37m\n"
    fi
    
    if [[ "${DNS_RECORD}" == *'"count":0'* ]];
    then
        ERROR=1
        echo -e " - ${DOMAIN} \e[1;31m${CROSS_MARK} A record not found!\e[1;37m\n"
    fi
    
    if [[ ${ERROR} == 0 ]];
    then
        DOMAIN_ID=$(echo ${DNS_RECORD} | awk '{ sub(/.*"id":"/, ""); sub(/",.*/, ""); print }')
        DOMAIN_IP=$(echo ${DNS_RECORD} | awk '{ sub(/.*"content":"/, ""); sub(/",.*/, ""); print }')
        DOMAIN_PROXIED=$(echo ${DNS_RECORD} | awk '{ sub(/.*"proxied":/, ""); sub(/,.*/, ""); print }')

        if [[ ${PUBLIC_IP} != ${DOMAIN_IP} ]];
        then
            DATA=$(printf '{"type":"A","name":"%s","content":"%s","proxied":%s}' "${DOMAIN}" "${PUBLIC_IP}" "${DOMAIN_PROXIED}")
            API_RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records/${DOMAIN_ID}" \
                -H "X-Auth-Email: ${EMAIL}" \
                -H "Authorization: Bearer ${TOKEN}" \
                -H "Content-Type: application/json" \
                --data ${DATA})

            if [[ ${API_RESPONSE} == *"\"success\":false"* ]];
            then
                echo -e " - ${DOMAIN} (\e[1;31m${DOMAIN_IP}\e[1;37m),\e[1;31m failed to update\e[1;37m\n"
            else
                echo -e " - ${DOMAIN} (\e[1;31m${DOMAIN_IP}\e[1;37m),\e[1;32m updated\e[1;37m\n"
            fi
        else
            echo -e " - ${DOMAIN} ${CHECK_MARK}\n"
        fi
    fi
}

while :
do
    PUBLIC_IP=$(wget -O - -q -t 1 https://api.ipify.org 2>/dev/null)
    echo -e "Time: $(date '+%Y-%m-%d %H:%M:%S')\n"
    if [[ ${SHOW_HIDE_PIP} == 1 ]];
    then
        Public IP address: ${PUBLIC_IP}\n
    fi

    # iterate through listed domains
    if [[ ${SORT} == true ]];
    then
        echo "Iterating domain list (sorted):"
        for ITEM in ${ARR[@]};
        do
            check ${ITEM}# $(bashio::config "domains[${ITEM}].domain")
        done #| sort -uk 1
    else
        echo "Iterating domain list:"
        for ITEM in ${ARR[@]};#$(bashio::config "domains|keys");
        do
            check ${ITEM} #$(bashio::config "domains[${ITEM}].domain")
        done
    fi

    NEXT=$(echo | busybox date -d@"$(( `busybox date +%s`+${INTERVAL}*60 ))" "+%Y-%m-%d %H:%M:%S")
    echo -e " \nNext check is at ${NEXT}\n "
    sleep ${INTERVAL}m

done
