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

# font
N="\e[0m"
I="\e[3m" #italic
S="\e[9m" #strikethrough

# regular colors:
RG="\e[0;32m" #green
RR="\e[0;31m" #red

# bold colors
W="\e[1;37m" #white
B="\e[1;30m" #black
BL="\e[1;34m" #blue
GR="\e[1;32m" #green
Y="\e[1;33m" #yellow
R="\e[1;31m" #red

if ! [[ ${EMAIL} == ?*@?*.?* ]];
then
    echo -e "${RR}Failed to run due to invalid email address${W}\n"
    exit 1
elif [[ ${#TOKEN} == 0 ]];
then
    echo -e "${RR}Failed to run due to missing Cloudflare API token${W}\n"
    exit 1
elif [[ ${#ZONE} == 0 ]];
then
    echo -e "${RR}Failed to run due to missing Cloudflare Zone ID${W}\n"
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
        echo -e " ${CROSS_MARK} ${DOMAIN} => ${R}${ERROR}${W}\n"
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
            echo -e " ${CROSS_MARK} ${DOMAIN} => ${R}${ERROR}${W}\n"
        else
            if [[ ${HIDE_PIP} == false ]];
            then
                if [[ ${PROXY} == false ]];
                then
                    echo -e " ${CHECK_MARK} ${DOMAIN} (${I}${R}not proxied${W}${N}) => ${GR}created${W}\n"
                else
                    echo -e " ${CHECK_MARK} ${DOMAIN} (${I}${RG}proxied${W}${N}) => ${GR}created${W}\n"
                fi
            else
                echo -e " ${CHECK_MARK} ${DOMAIN} => ${GR}created${W}\n"
            fi
        fi
    fi
    
    if [[ ${ERROR} == 0 ]];
    then
        DOMAIN_ID=$(echo ${API_RESPONSE} | awk '{ sub(/.*"id":"/, ""); sub(/",.*/, ""); print }')
        DOMAIN_IP=$(echo ${API_RESPONSE} | awk '{ sub(/.*"content":"/, ""); sub(/",.*/, ""); print }')
        DOMAIN_PROXIED=$(echo ${API_RESPONSE} | awk '{ sub(/.*"proxied":/, ""); sub(/,.*/, ""); print }')

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
                    if [[ ${DOMAIN_PROXIED} == false ]];
                    then
                        echo -e " ${CROSS_MARK} ${DOMAIN} ${DOMAIN_IP} (${I}${R}not proxied${W}${N}) => ${RR}failed to update${W}\n"
                    else
                        echo -e " ${CHECK_MARK} ${DOMAIN} (${I}${RG}proxied${W}${N}) => ${GR}created${W}\n"
                    fi
                else
                    echo -e " ${CROSS_MARK} ${DOMAIN} => ${RR}failed to update${W}\n"
                fi
            else

                if [[ ${HIDE_PIP} == false ]];
                then
                    if [[ ${DOMAIN_PROXIED} == false ]];
                    then
                        echo -e " ${CHECK_MARK} ${DOMAIN} (${I}${R}not proxied${W}${N}) => ${GR}updated${W} (\e[9m${Y}${DOMAIN_IP}${W}\e[0m)\n"
                    else
                        echo -e " ${CHECK_MARK} ${DOMAIN} (${I}${RG}proxied${W}${N}) => ${GR}updated${W} (\e[9m${Y}${DOMAIN_IP}${W}\e[0m)\n"
                    fi
                else
                    echo -e " ${CHECK_MARK} ${DOMAIN} => ${GR}updated${W}\n"
                fi
                # (${R}${DOMAIN_IP}${W}), ${GR}updated${W}\n"
             fi
        else
            if [[ ${HIDE_PIP} == false ]];
            then
                if [[ ${DOMAIN_PROXIED} == false ]];
                then
                    echo -e " ${CHECK_MARK} ${DOMAIN} (${I}${R}not proxied${W}${N})\n";
                else
                    echo -e " ${CHECK_MARK} ${DOMAIN} (${I}${RG}proxied${W}${N})\n";
                fi
            else
                echo -e " ${CHECK_MARK} ${DOMAIN}\n"
            fi
        fi
    fi
}

if [[ ${INTERVAL} == 1 ]]; then bashio::log.info "Iterating every minute\n "; else bashio::log.info "Iterating every ${INTERVAL} minutes\n "; fi

while :
do
    PUBLIC_IP=$(wget -O - -q -t 1 https://api.ipify.org 2>/dev/null)
    echo -e "Time: $(date '+%Y-%m-%d %H:%M:%S')\n"
    NEXT=$(echo | busybox date -d@"$(( `busybox date +%s`+${INTERVAL}*60 ))" "+%Y-%m-%d %H:%M:%S")
    echo -e "Next: ${NEXT}\n"
    if [[ ${HIDE_PIP} == false ]]; then echo -e "Public IP address: ${BL}${PUBLIC_IP}${W}\n"; fi
    
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
    
    echo -e "\n "
    sleep ${INTERVAL}m

done
