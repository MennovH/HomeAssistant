#!/usr/bin/env bashio

declare EMAIL
declare TOKEN
declare ZONE
declare INTERVAL
declare SHOW_HIDE_PIP
declare DOMAINS

EMAIL=$(bashio::config 'email_address' | xargs echo -n)
TOKEN=$(bashio::config 'cloudflare_api_token'| xargs echo -n)
ZONE=$(bashio::config 'cloudflare_zone_id'| xargs echo -n)
INTERVAL=$(bashio::config 'interval')
SHOW_HIDE_PIP=$(bashio::config 'hide_public_ip')
AUTO_CREATE=$(bashio::config 'auto_create')
API_RESPONSE=""
CHECK_MARK="\033[0;32m\xE2\x9C\x94\033[0m"
CROSS_MARK="\u274c"

DOMAINS=$(for j in $(bashio::config "domains|keys"); do echo $(bashio::config "domains[${j}].domain"); done | sort -uk 1 | xargs echo -n)

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
    result=$(curl -sX GET "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records?type=A&name=${DOMAIN}&page=1&per_page=100&match=all" \
        -H "X-Auth-Email: ${EMAIL}" \
        -H "Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json")
    echo -e $result
}

update () {
    DATA=$(printf '{"type":"A","name":"%s","content":"%s","proxied":%s}' "${DOMAIN}" "${PUBLIC_IP}" "${DOMAIN_PROXIED}")
    result=$(curl -sX PUT "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records/${DOMAIN_ID}" \
        -H "X-Auth-Email: ${EMAIL}" \
        -H "Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json" \
        --data ${DATA})
    echo -e $result
}

create () {
    DATA=$(printf '{"type":"A","name":"%s","content":"%s","proxied":%s}' "${DOMAIN}" "${PUBLIC_IP}" "true")
    result=$(curl -sX POST "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records" \
        -H "X-Auth-Email: ${EMAIL}" \
        -H "Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json" \
        --data ${DATA})
    echo -e $result
}

find () {
    ERROR=0
    DOMAIN=$1
    check
    API_RESPONSE=$?

    if [[ ${API_RESPONSE} == *"\"success\":false"* ]];
    then
        ERROR=$(echo ${DNS_RECORD} | awk '{ sub(/.*"message":"/, ""); sub(/".*/, ""); print }')
        echo -e " - ${DOMAIN} \e[1;31m${CROSS_MARK} ${ERROR}\e[1;37m\n"
    fi
    
    if [[ "${API_RESPONSE}" == *'"count":0'* ]];
    then
        ERROR=1
        
        if [[ ${AUTO_CREATE} == 1 ]];
        then
            create
            API_RESPONSE=$?
            if [[ ${API_RESPONSE} == *"\"success\":false"* ]];
            then
                ERROR=$(echo ${DNS_RECORD} | awk '{ sub(/.*"message":"/, ""); sub(/".*/, ""); print }')
                echo -e " - ${DOMAIN} \e[1;31m${CROSS_MARK} ${ERROR}\e[1;37m\n"
            else
                echo -e " - ${DOMAIN} \e[1;32m created\e[1;37m\n"
            fi
            
        else
            echo -e " - ${DOMAIN} \e[1;31m${CROSS_MARK} A record not found!\e[1;37m\n"
        fi
    fi
    
    if [[ ${ERROR} == 0 ]];
    then
        DOMAIN_ID=$(echo ${API_RESPONSE} | awk '{ sub(/.*"id":"/, ""); sub(/",.*/, ""); print }')
        DOMAIN_IP=$(echo ${API_RESPONSE} | awk '{ sub(/.*"content":"/, ""); sub(/",.*/, ""); print }')
        DOMAIN_PROXIED=$(echo ${API_RESPONSE} | awk '{ sub(/.*"proxied":/, ""); sub(/,.*/, ""); print }')

        if [[ ${PUBLIC_IP} != ${DOMAIN_IP} ]];
        then
        
            update
            API_RESPONSE=$?

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
    echo "Iterating domain list:"
    for ITEM in ${DOMAINS[@]};
    do
        find ${ITEM}
    done
        
    NEXT=$(echo | busybox date -d@"$(( `busybox date +%s`+${INTERVAL}*60 ))" "+%Y-%m-%d %H:%M:%S")
    echo -e " \nNext check is at ${NEXT}\n "
    sleep ${INTERVAL}m

done
