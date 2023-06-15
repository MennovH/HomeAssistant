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
CREATION_ERRORS=0
ITERATION_ERRORS=0
UPDATE_ERRORS=0 
PIP_ERRORS=0

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

if [[ ${#ZONE} == 0 ]];
then
    echo -e "${RR}Failed to run due to missing Cloudflare Zone ID${N}"
    exit 1
elif [[ ${#TOKEN} == 0 ]];
then
    echo -e "${RR}Failed to run due to missing Cloudflare API token${N}"
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
            CREATION_ERRORS=$(($CREATION_ERRORS + 1))
            ERROR=$(echo ${API_RESPONSE} | awk '{ sub(/.*"message":"/, ""); sub(/".*/, ""); print }')
            echo -e " ${CROSS_MARK} ${DOMAIN} => ${R}${ERROR}${N}"
        else
            # creation successful (no need to mention current PIP (again))
            if [[ ${PROXY} == false ]];
            then
                echo -e " ${CHECK_MARK} ${DOMAIN} (${RR}${I}not proxied${N}) => ${GR}created${N}"
            else
                echo -e " ${CHECK_MARK} ${DOMAIN} (${RG}${I}proxied${N}) => ${GR}created${N}"
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
                UPDATE_ERRORS=$(($UPDATE_ERRORS + 1))
                if [[ ${HIDE_PIP} == false ]];
                then
                    # show current assigned PIP
                    if [[ ${DOMAIN_PROXIED} == false ]];
                    then
                        echo -e " ${CROSS_MARK} ${DOMAIN} (${RR}${DOMAIN_IP}${N}) (${RR}${I}not proxied${N}) => ${R}failed to update${N}"
                    else
                        echo -e " ${CHECK_MARK} ${DOMAIN} (${RR}${DOMAIN_IP}${N}) (${RG}${I}proxied${N}) => ${R}failed to update${N}"
                    fi
                else
                    # don't show current assigned PIP
                    if [[ ${DOMAIN_PROXIED} == false ]];
                    then
                        echo -e " ${CROSS_MARK} ${DOMAIN} (${RR}${I}not proxied${N}) => ${R}failed to update${N}"
                    else
                        echo -e " ${CHECK_MARK} ${DOMAIN} (${RG}${I}proxied${N}) => ${R}failed to update${N}"
                    fi
                fi
            else
                # update successful
                if [[ ${HIDE_PIP} == false ]];
                then
                    # show previously assigned PIP
                    if [[ ${DOMAIN_PROXIED} == false ]];
                    then
                        echo -e " ${CHECK_MARK} ${DOMAIN} (${RR}${I}not proxied${N}) => ${GR}updated${N} (${YY}${S}${DOMAIN_IP}${N}\e[0m)"
                    else
                        echo -e " ${CHECK_MARK} ${DOMAIN} (${RG}${I}proxied${N}) => ${GR}updated${N} (${YY}${S}${DOMAIN_IP}${N}\e[0m)"
                    fi
                else
                    # don't show previously assigned PIP
                    if [[ ${DOMAIN_PROXIED} == false ]];
                    then
                        echo -e " ${CHECK_MARK} ${DOMAIN} (${RR}${I}not proxied${N}) => ${GR}updated${N}"
                    else
                        echo -e " ${CHECK_MARK} ${DOMAIN} (${RG}${I}proxied${N}) => ${GR}updated${N}"
                    fi
                fi
             fi
        else
            # nothing changed
            if [[ ${DOMAIN_PROXIED} == false ]];
            then
                echo -e " ${CHECK_MARK} ${DOMAIN} (${RR}${I}not proxied${N})";
            else
                echo -e " ${CHECK_MARK} ${DOMAIN} (${RG}${I}proxied${N})";
            fi
        fi
    fi
}

if [[ ${INTERVAL} == 1 ]]; then bashio::log.info "Iterating every minute\n "; else bashio::log.info "Iterating every ${INTERVAL} minutes\n "; fi

while :
do
    #PUBLIC_IP=$(wget -O - -q -t 1 https://api.ipify.org 2>/dev/null)
    PUBLIC_IP=$(curl -s --connect-timeout 5 https://api.ipify2.org)
    echo -e "$PUBLIC_IP"
    echo -e "Time: $(date '+%Y-%m-%d %H:%M:%S')"

    if [[ ! -z "$PUBLIC_IP" ]];
    then
        NEXT=$(echo | busybox date -d@"$(( `busybox date +%s`+${INTERVAL}*60 ))" "+%Y-%m-%d %H:%M:%S")
        SECONDS=0
        echo -e "Next: ${NEXT}"
        echo -e "Errors (PIP/iteration/creation/update): ${PIP_ERRORS}/${ITERATION_ERRORS}/${CREATION_ERRORS}/${UPDATE_ERRORS}"
        if [[ ${HIDE_PIP} == false ]]; then echo -e "Public IP address: ${BL}${PUBLIC_IP}${N}\n"; fi
        
        # fetch existing A records
        DOMAINS=$(curl -sX GET "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records?type=A" \
            -H "Authorization: Bearer ${TOKEN}" \
            -H "Content-Type: application/json" | jq -r '.result[].name')
        
        if [[ ! -z "$DOMAINS" ]];
        then
            count=$(wc -w <<< $PERSISTENT_DOMAINS)
            if [[ $count > 0 ]];
            then
                # add persistent domains to obtained record list
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
                # iterate through listed domains
                ITERATION=$(($ITERATION + 1))
                echo "Domain list iteration ${ITERATION}:"
                for DOMAIN in ${DOMAIN_LIST[@]}; do check ${DOMAIN}; done
                echo -e "\n "
                duration=$SECONDS
                TMP_SEC=$(((($INTERVAL*60)-($duration/60))-($duration%60)-1))
                sleep ${TMP_SEC}s
            else
                # iteration failed
                ITERATION_ERRORS=$(($ITERATION_ERRORS + 1))
                echo -e "${RR}Domain list iteration failed. Retrying in 60 seconds...${N}"
                sleep 60s
            fi
        else
            # iteration failed
            ITERATION_ERRORS=$(($ITERATION_ERRORS + 1))
            echo -e "${RR}Domain list iteration failed. Retrying in 60 seconds...${N}"
            sleep 60s
        fi
    else
        # PIP fetch failed
        PIP_ERRORS=$(($PIP_ERRORS + 1))
        echo -e "${RR}Retrieving PIP failed. Retrying in 60 seconds...${N}"
        sleep 60s
    fi
done
echo -e "$PUBLIC_IP"
