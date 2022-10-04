#!/usr/bin/env bashio

declare EMAIL
declare TOKEN
declare ZONE
declare DOMAINS
declare INTERVAL

EMAIL=$(bashio::config 'email_address')
TOKEN=$(bashio::config 'cloudflare_api_token')     
ZONE=$(bashio::config 'cloudflare_zone_id')
DOMAINS=$(bashio::config 'domains')
INTERVAL=$(bashio::config 'interval')

if [[ ${INTERVAL} == 1 ]];
then
    echo -e "Updating DDNS every minute\n "
else
    echo -e "Updating DDNS every ${INTERVAL} minutes\n "
fi

while :
do
    PUBLIC_IP=$(wget -O - -q -t 1 https://api.ipify.org 2>/dev/null)
    echo -e "Time: $(date '+%Y-%m-%d %H:%M')\nPublic IP address: ${PUBLIC_IP}\nIterating domain list:"

    for DOMAIN in ${DOMAINS[@]}
    do
        DNS_RECORD=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records?type=A&name=${DOMAIN}&page=1&per_page=100&match=all" \
         -H "X-Auth-Email: ${EMAIL}" \
         -H "Authorization: Bearer ${TOKEN}" \
         -H "Content-Type: application/json")

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
 #               bashio::log.alert "Failed to update ${DOMAIN} (is ${DOMAIN_IP})"
                echo -e " -\e[1;31m ${DOMAIN} (${DOMAIN_IP}), failed to update\n"
            else
 #               bashio::log.info "Updated ${DOMAIN} (was ${DOMAIN_IP})"
                echo -e " -\e[1;32m ${DOMAIN} (${DOMAIN_IP}), updated\n"
            fi
        else

            echo -e " - ${DOMAIN}, up-to-date\n"
        fi
    done

    if [[ ${INTERVAL} == 1 ]];
    then
        echo -e " \nWaiting 1 minute for next check...\n "
    else
        echo -e " \nWaiting ${INTERVAL} minutes for next check...\n "
    fi
    sleep ${INTERVAL}m

done
