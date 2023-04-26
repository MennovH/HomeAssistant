#!/usr/bin/env bashio

declare EMAIL
declare TOKEN
declare ZONE
declare INTERVAL
declare HIDE_PIP
declare DOMAINS
declare HARDCODED_DOMAINS

EMAIL=$(bashio::config 'email_address' | xargs echo -n)
TOKEN=$(bashio::config 'cloudflare_api_token'| xargs echo -n)
ZONE=$(bashio::config 'cloudflare_zone_id'| xargs echo -n)
INTERVAL=$(bashio::config 'interval')
HIDE_PIP=$(bashio::config 'hide_public_ip')
HARDCODED_DOMAINS=$(for j in $(bashio::config "domains|keys"); do echo $(bashio::config "domains[${j}].domain"); done | xargs echo -n)
CHECK_MARK="\033[0;32m\xE2\x9C\x94\033[0m"
CROSS_MARK="\u274c"

# colors
D="\e[1;37m" #default
G="\e[1;30m" #grey
GR="\e[1;32m" #green
O="\e[1;66m" #orange
R="\e[1;31m" #red

if ! [[ ${EMAIL} == ?*@?*.?* ]];
then
    echo -e "${R}Failed to run due to invalid email address${D}\n"
    exit 1
elif [[ ${#TOKEN} == 0 ]];
then
    echo -e "${R}Failed to run due to missing Cloudflare API token${D}\n"
    exit 1
elif [[ ${#ZONE} == 0 ]];
then
    echo -e "${R}Failed to run due to missing Cloudflare Zone ID${D}\n"
    exit 1
fi

function domain_lookup {
  local list="$1"
  local item="$2"
  if [[ $list =~ (^|[[:space:]])"$item"($|[[:space:]]) ]] ; then result=1; else result=0; fi
  return $result
}

function check {
    ERROR=0
    DOMAIN=$1
    PROXY=true
    if [[ ${DOMAIN} == *"_no_proxy"* ]];
    then
        DOMAIN=$(sed "s/_no_proxy/""/" <<< "$DOMAIN")
        PROXY=false
    fi
    API_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records?type=A&name=${DOMAIN}&page=1&per_page=100&match=all" \
        -H "X-Auth-Email: ${EMAIL}" \
        -H "Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json")
        
    if [[ ${API_RESPONSE} == *"\"success\":false"* ]];
    then
        ERROR=$(echo ${API_RESPONSE} | awk '{ sub(/.*"message":"/, ""); sub(/".*/, ""); print }')
        echo -e " ${CROSS_MARK} ${DOMAIN} => ${R}${ERROR}${D}\n"
    fi
    
    if [[ "${API_RESPONSE}" == *'"count":0'* ]];
    then
        ERROR=1
        DATA=$(printf '{"type":"A","name":"%s","content":"%s","ttl":1,"proxied":%s}' "${DOMAIN}" "${PUBLIC_IP}" "${PROXY}")
        API_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records" \
            -H "X-Auth-Email: ${EMAIL}" \
            -H "Authorization: Bearer ${TOKEN}" \
            -H "Content-Type: application/json" \
            --data ${DATA})

        if [[ ${API_RESPONSE} == *"\"success\":false"* ]];
        then
            ERROR=$(echo ${API_RESPONSE} | awk '{ sub(/.*"message":"/, ""); sub(/".*/, ""); print }')
            echo -e " ${CROSS_MARK} ${DOMAIN} => ${R}${ERROR}${D}\n"
        else
            if [[ ${HIDE_PIP} == false ]];
            then
                echo -e " ${CHECK_MARK} ${DOMAIN} ${PROXY} => ${GR}created${D}\n"
            else
                echo -e " ${CHECK_MARK} ${DOMAIN} => ${GR}created${D}\n"
            fi
        fi
    fi
    
    if [[ ${ERROR} == 0 ]];
    then
        DOMAIN_ID=$(echo ${API_RESPONSE} | awk '{ sub(/.*"id":"/, ""); sub(/",.*/, ""); print }')
        DOMAIN_IP=$(echo ${API_RESPONSE} | awk '{ sub(/.*"content":"/, ""); sub(/",.*/, ""); print }')
        DOMAIN_PROXIED=$(echo ${API_RESPONSE} | awk '{ sub(/.*"proxied":/, ""); sub(/,.*/, ""); print }')

        if [[ ${DOMAIN_PROXIED} == false ]];
        then
            PROXY_STATUS=$(echo -e "${G}not proxied${D}")
        else
            PROXY_STATUS=$(echo -e "${O}proxied${D}")
        fi

        if [[ ${PUBLIC_IP} != ${DOMAIN_IP} ]];
        then
            DATA=$(printf '{"type":"A","name":"%s","content":"%s","proxied":%s}' "${DOMAIN}" "${PUBLIC_IP}" "${DOMAIN_PROXIED}")
            API_RESPONSE=$(curl -sX PUT "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records/${DOMAIN_ID}" \
                -H "X-Auth-Email: ${EMAIL}" \
                -H "Authorization: Bearer ${TOKEN}" \
                -H "Content-Type: application/json" \
                --data ${DATA})

            if [[ ${API_RESPONSE} == *"\"success\":false"* ]];
            then
                if [[ ${HIDE_PIP} == false ]];
                then
                    echo -e " ${CROSS_MARK} ${DOMAIN} ${DOMAIN_IP} (${PROXY_STATUS}) => ${R}failed to update${D}\n"
                else
                    echo -e " ${CROSS_MARK} ${DOMAIN} => ${R}failed to update${D}\n"
                fi
                # (${R}${DOMAIN_IP}${D}), ${R}failed to update${D}\n"
            else

                if [[ ${HIDE_PIP} == false ]];
                then
                    echo -e " ${CHECK_MARK} ${DOMAIN} ${DOMAIN_IP} (${PROXY_STATUS}) => ${GR}updated${D}\n"
                else
                    echo -e " ${CHECK_MARK} ${DOMAIN} => ${GR}updated${D}\n"
                fi
                # (${R}${DOMAIN_IP}${D}), ${GR}updated${D}\n"
            fi
        else
            if [[ ${HIDE_PIP} == false ]];
            then
                echo -e " ${CHECK_MARK} ${DOMAIN} (${PROXY_STATUS})\n";
            else
                echo -e " ${CHECK_MARK} ${DOMAIN}\n"
            fi
        fi
    fi
}

if [[ ${INTERVAL} == 1 ]]; then echo -e "Checking A records every minute\n "; else echo -e "Checking A records every ${INTERVAL} minutes\n "; fi

while :
do
    PUBLIC_IP=$(wget -O - -q -t 1 https://api.ipify.org 2>/dev/null)
    echo -e "Time: $(date '+%Y-%m-%d %H:%M:%S')\n"
    if [[ ${HIDE_PIP} == false ]]; then echo -e "Public IP address: ${PUBLIC_IP}\n"; fi
    
    DOMAINS=$(curl -sX GET "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records?type=A" \
        -H "X-Auth-Email: ${EMAIL}" \
        -H "Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json" | jq -r '.result[].name')
        
    count=$(wc -w <<< $HARDCODED_DOMAINS)
    if [[ $count > 0 ]];
    then
        for DOMAIN in ${HARDCODED_DOMAINS[@]};
        do 
            TMP_DOMAIN=$(sed "s/_no_proxy/""/" <<< "$DOMAIN")
            
            if `domain_lookup "$DOMAINS" "$TMP_DOMAIN"`;
            then
                DOMAINS+=("$DOMAIN")
            fi
            HARDCODED_DOMAINS=( "${HARDCODED_DOMAINS[@]/$DOMAIN/}" )
        done
    fi
    
    DOMAIN_LIST=($(for d in "${DOMAINS[@]}"; do echo "${d}"; done | sort -u))
    
    # iterate through listed domains
    echo "Iterating domain list:"
    for DOMAIN in ${DOMAIN_LIST[@]}; do check ${DOMAIN}; done
    
    NEXT=$(echo | busybox date -d@"$(( `busybox date +%s`+${INTERVAL}*60 ))" "+%Y-%m-%d %H:%M:%S")
    echo -e " \nNext check is at ${NEXT}\n "
    sleep ${INTERVAL}m

done
