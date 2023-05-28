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
N="\e[0m" #normal
I="\e[3m" #italic
S="\e[9m" #strikethrough

# colors:
RG="\e[0;32m" #regular green
RR="\e[0;31m" #regular red
YY="\e[0;33m" #regular yellow
BL="\e[1;34m" #bold blue
GR="\e[1;32m" #bold green
R="\e[1;31m" #bold red (error)

CREATIONERRORCOUNT=0
ITERATIONERRORCOUNT=0
UPDATEERRORCOUNT=0 

if [[ ${#ZONE} == 0 ]];
then
    echo -e "${RR}Failed to run due to missing Cloudflare Zone ID${N}\n"
    exit 1
elif [[ ${#TOKEN} == 0 ]];
then
    echo -e "${RR}Failed to run due to missing Cloudflare API token${N}\n"
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
        echo -e " ${CROSS_MARK} ${DOMAIN} => ${R}${ERROR}${N}\n"
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
            CREATIONERRORCOUNT=$(($CREATIONERRORCOUNT + 1))
            ERROR=$(echo ${API_RESPONSE} | awk '{ sub(/.*"message":"/, ""); sub(/".*/, ""); print }')
            echo -e " ${CROSS_MARK} ${DOMAIN} => ${R}${ERROR}${N}\n"
        else
            # creation successful (no need to mention current PIP (again))
            if [[ ${PROXY} == false ]];
            then
                echo -e " ${CHECK_MARK} ${DOMAIN} (${RR}${I}not proxied${N}) => ${GR}created${N}\n"
            else
                echo -e " ${CHECK_MARK} ${DOMAIN} (${RG}${I}proxied${N}) => ${GR}created${N}\n"
            fi
        fi
    fi
    
    if [[ ${ERROR} == 0 ]];
    then
        DOMAIN_ID=$(echo ${API_RESPONSE} | awk '{ sub(/.*"id":"/, ""); sub(/",.*/, ""); print }')
        DOMAIN_IP=$(echo ${API_RESPONSE} | awk '{ sub(/.*"content":"/, ""); sub(/",.*/, ""); print }')
        DOMAIN_PROXIED=$(echo ${API_RESPONSE} | awk '{ sub(/.*"proxied":/, ""); sub(/,.*/, ""); print }')
        
        UPDATEERRORCOUNT=$(($UPDATEERRORCOUNT + 1))
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
                
                UPDATEERRORCOUNT=$(($UPDATEERRORCOUNT + 1))
                if [[ ${HIDE_PIP} == false ]];
                then
                    # show current assigned PIP
                    if [[ ${DOMAIN_PROXIED} == false ]];
                    then
                        echo -e " ${CROSS_MARK} ${DOMAIN} (${RR}${DOMAIN_IP}${N}) (${RR}${I}not proxied${N}) => ${R}failed to update${N}\n"
                    else
                        echo -e " ${CHECK_MARK} ${DOMAIN} (${RR}${DOMAIN_IP}${N}) (${RG}${I}proxied${N}) => ${R}failed to update${N}\n"
                    fi
                else
                    # don't show current assigned PIP
                    if [[ ${DOMAIN_PROXIED} == false ]];
                    then
                        echo -e " ${CROSS_MARK} ${DOMAIN} (${RR}${I}not proxied${N}) => ${R}failed to update${N}\n"
                    else
                        echo -e " ${CHECK_MARK} ${DOMAIN} (${RG}${I}proxied${N}) => ${R}failed to update${N}\n"
                    fi
                fi
            else
                # update successful
                if [[ ${HIDE_PIP} == false ]];
                then
                    # show previously assigned PIP
                    if [[ ${DOMAIN_PROXIED} == false ]];
                    then
                        echo -e " ${CHECK_MARK} ${DOMAIN} (${RR}${I}not proxied${N}) => ${GR}updated${N} (${YY}\e[9m${DOMAIN_IP}${N}\e[0m)\n"
                    else
                        echo -e " ${CHECK_MARK} ${DOMAIN} (${RG}${I}proxied${N}) => ${GR}updated${N} (${YY}\e[9m${DOMAIN_IP}${N}\e[0m)\n"
                    fi
                else
                    # don't show previously assigned PIP
                    if [[ ${DOMAIN_PROXIED} == false ]];
                    then
                        echo -e " ${CHECK_MARK} ${DOMAIN} (${RR}${I}not proxied${N}) => ${GR}updated${N}\n"
                    else
                        echo -e " ${CHECK_MARK} ${DOMAIN} (${RG}${I}proxied${N}) => ${GR}updated${N}\n"
                    fi
                fi
             fi
        else
            # nothing changed
            if [[ ${DOMAIN_PROXIED} == false ]];
            then
                echo -e " ${CHECK_MARK} ${DOMAIN} (${RR}${I}not proxied${N})\n";
            else
                echo -e " ${CHECK_MARK} ${DOMAIN} (${RG}${I}proxied${N})\n";
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
    echo -e "Errors (iteration/creation/update): ${ITERATIONERRORCOUNT}/${CREATIONERRORCOUNT}/${UPDATEERRORCOUNT}\n"
    if [[ ${HIDE_PIP} == false ]]; then echo -e "Public IP address: ${BL}${PUBLIC_IP}${N}\n"; fi
    
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
            ITERATIONERRORCOUNT=$(($ITERATIONERRORCOUNT + 1))
            echo -e "${RR}Domain list iteration failed. Retrying...${N}"
        fi
    else
        ITERATIONERRORCOUNT=$(($ITERATIONERRORCOUNT + 1))
        echo -e "${RR}Domain list iteration failed. Retrying...${N}"
    fi
done
