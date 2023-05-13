#!/usr/bin/env bashio

declare TOKEN
declare ZONE
declare INTERVAL
declare HIDE_PIP
declare DOMAINS
declare PERSISTENT_DOMAINS
declare CHECK_MARK
declare CROSS_MARK

TOKEN=$(bashio::config 'cloudflare_api_token'| xargs echo -n)
ZONE=$(bashio::config 'cloudflare_zone_id'| xargs echo -n)
INTERVAL=$(bashio::config 'interval')
HIDE_PIP=$(bashio::config 'hide_public_ip')
PERSISTENT_DOMAINS=$(bashio::config "domains")
CHECK_MARK="\033[0;32m\xE2\x9C\x94\033[0m"
CROSS_MARK="\u274c"
ITERATION=0

# font
N="\e[0m"
I="\e[3m" #italic
S="\e[9m" #strikethrough

# regular colors:
RG="\e[0;32m" #green
RR="\e[0;31m" #red
YY="\e[0;33m" #yellow
GREY="\e[1;30m" #grey

# bold colors
W="\e[1;37m" #white
B="\e[1;30m" #black
BL="\e[1;34m" #blue
GR="\e[1;32m" #green
Y="\e[1;33m" #yellow
R="\e[1;31m" #red

if [[ ${#ZONE} == 0 ]];
then
    echo -e "${RR}Failed to run due to missing Cloudflare Zone ID${W}\n"
    exit 1
elif [[ ${#TOKEN} == 0 ]];
then
    echo -e "${RR}Failed to run due to missing Cloudflare API token${W}\n"
    exit 1
fi

function domain_lookup {
  local LIST="$1"
  local ITEM="$2"
  if [[ $LIST =~ (^|[[:space:]])"$ITEM"($|[[:space:]]) ]] ; then RESULT=1; else RESULT=0; fi
  return $RESULT
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
            -H "Authorization: Bearer ${TOKEN}" \
            -H "Content-Type: application/json" \
            --data ${DATA})

        if [[ ${API_RESPONSE} == *"\"success\":false"* ]];
        then
            # creation failed
            ERROR=$(echo ${API_RESPONSE} | awk '{ sub(/.*"message":"/, ""); sub(/".*/, ""); print }')
            echo -e " ${CROSS_MARK} ${DOMAIN} => ${R}${ERROR}${W}\n"
        else
            # creation successful (no need to mention current PIP (again))
            if [[ ${PROXY} == false ]];
            then
                echo -e " ${CHECK_MARK} ${YY}${DOMAIN}${W} => ${GR}created${W}\n"
            else
                echo -e " ${CHECK_MARK} ${RG}${DOMAIN}${W} => ${GR}created${W}\n"
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
            # difference detected
            DATA=$(printf '{"type":"A","name":"%s","content":"%s","proxied":%s}' "${DOMAIN}" "${PUBLIC_IP}" "${DOMAIN_PROXIED}")
            API_RESPONSE=$(curl -sX PUT "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records/${DOMAIN_ID}" \
                -H "Authorization: Bearer ${TOKEN}" \
                -H "Content-Type: application/json" \
                --data ${DATA})

            if [[ ${API_RESPONSE} == *"\"success\":false"* ]];
            then
                # update failed
                if [[ ${HIDE_PIP} == false ]];
                then
                    # show current assigned PIP
                    if [[ ${DOMAIN_PROXIED} == false ]];
                    then
                        echo -e " ${CROSS_MARK} ${GREY}${DOMAIN}${W}) (${R}${DOMAIN_IP}${W}) => ${RR}failed to update${W}\n"
                    else
                        echo -e " ${CHECK_MARK} ${YY}${DOMAIN}${W} (${R}${DOMAIN_IP}${W}) => ${RR}failed to update${W}\n"
                    fi
                else
                    # don't show current assigned PIP
                    if [[ ${DOMAIN_PROXIED} == false ]];
                    then
                        echo -e " ${CROSS_MARK} ${GREY}${DOMAIN}${W}) => ${RR}failed to update${W}\n"
                    else
                        echo -e " ${CHECK_MARK} ${YY}${DOMAIN}${W} => ${RR}failed to update${W}\n"
                    fi
                fi
            else
                # update successful
                if [[ ${HIDE_PIP} == false ]];
                then
                    # show previously assigned PIP
                    if [[ ${DOMAIN_PROXIED} == false ]];
                    then
                        echo -e " ${CHECK_MARK} ${GREY}${DOMAIN}${W}) => ${GR}updated${W} (\e[9m${DOMAIN_IP}\e[0m)\n"
                    else
                        echo -e " ${CHECK_MARK} ${YY}${DOMAIN}${W} => ${GR}updated${W} (\e[9m${DOMAIN_IP}\e[0m)\n"
                    fi
                else
                    # don't show previously assigned PIP
                    if [[ ${DOMAIN_PROXIED} == false ]];
                    then
                        echo -e " ${CHECK_MARK} ${GREY}${DOMAIN}${W}) => ${GR}updated${W}\n"
                    else
                        echo -e " ${CHECK_MARK} ${YY}${DOMAIN}${W} => ${GR}updated${W}\n"
                    fi
                fi
             fi
        else
            # nothing changed
            if [[ ${DOMAIN_PROXIED} == false ]];
            then
                echo -e " ${CHECK_MARK} ${GREY}${DOMAIN}${W})\n";
            else
                echo -e " ${CHECK_MARK} ${YY}${DOMAIN}${W}\n";
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
    SECONDS=0
    echo -e "Next: ${NEXT}\n"
    if [[ ${HIDE_PIP} == false ]]; then echo -e "Public IP address: ${BL}${PUBLIC_IP}${W}\n"; fi
    
    DOMAINS=$(curl -sX GET "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records?type=A" \
        -H "Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json" | jq -r '.result[].name')
    
    if [[ ! -z "$DOMAINS" ]];
    then
        count=$(wc -w <<< $PERSISTENT_DOMAINS)
        if [[ $count > 0 ]];
        then
            for DOMAIN in ${PERSISTENT_DOMAINS[@]};
            do 
                TMP_DOMAIN=$(sed "s/_no_proxy/""/" <<< "$DOMAIN")
                if `domain_lookup "$DOMAINS" "$TMP_DOMAIN"`;
                then
                    DOMAINS+=("$DOMAIN")
                fi
                PERSISTENT_DOMAINS=( "${PERSISTENT_DOMAINS[@]/$DOMAIN/}" )
            done
        fi
    
        DOMAIN_LIST=($(for D in "${DOMAINS[@]}"; do echo "${D}"; done | sort -u))
        
        if [[ ! -z "$DOMAIN_LIST" ]];
        then
            ITERATION=$(($ITERATION + 1))
            # iterate through listed domains
            echo "Domain list iteration ${ITERATION}:"
            for DOMAIN in ${DOMAIN_LIST[@]}; do check ${DOMAIN}; done
            echo -e "\n "
            duration=$SECONDS
            TMP_SEC=$(((($INTERVAL*60)-($duration/60))-($duration%60)-1))
            sleep ${TMP_SEC}s
        else
            echo -e "${R}Domain list iteration failed. Retrying...${W}"
        fi
    else
        echo -e "${R}Domain list iteration failed. Retrying...${W}"
    fi
done
