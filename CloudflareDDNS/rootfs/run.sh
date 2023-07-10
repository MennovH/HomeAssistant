#!/usr/bin/env bashio

declare TOKEN
declare ZONE
declare INTERVAL
declare LOG_PIP
declare DOMAINS
declare PERSISTENT_DOMAINS
declare RELOAD_SYMBOL
declare CROSS_MARK

# variables
TOKEN=$(bashio::config 'cloudflare_api_token'| xargs echo -n)
ZONE=$(bashio::config 'cloudflare_zone_id'| xargs echo -n)
INTERVAL=$(bashio::config 'interval')
LOG_PIP=$(bashio::config 'log_pip')
PERSISTENT_DOMAINS=$(bashio::config "domains")
CROSS_MARK="\u274c"
PLUS="\uff0b"
BULLET="\u2022"
RELOAD_SYMBOL="\u21bb"
PREVIOUS_PIP=""

# counters
ITERATION=0
CREATION_ERRORS=0
ITERATION_ERRORS=0
UPDATE_ERRORS=0 
PIP_ERRORS=0
NEW_PIP_COUNTER=0
UPDATE_COUNTER=0
CREATION_COUNTER=0

# font
N="\e[0m" #normal
I="\e[3m" #italic
S="\e[9m" #strikethrough
U="\e[4m" #underline

# colors
RG="\e[0;32m" #regular green
RR="\e[0;31m" #regular red
RY="\e[0;33m" #regular yellow
GR="\e[1;30m" #grey
BB="\e[1;34m" #bold blue
BG="\e[1;32m" #bold green
R="\e[1;31m" #bold red (error)

echo -e "${RY}☁${N} Initializing add-on ☁"

# checks on configuration
if [[ ${#ZONE} == 0 ]];
then
    echo -e "${RR}Failed to run due to missing Cloudflare Zone ID${N}"
    exit 1
elif [[ ${#TOKEN} == 0 ]];
then
    echo -e "${RR}Failed to run due to missing Cloudflare API token${N}"
    exit 1
fi

# function to return log message that holds the PIP
function show_pip {
    local IP="$1"
    if [[ ${LOG_PIP} == true ]]; then echo -e " (${RY}${S}${IP}${N}\e[0m)"; fi
}

# function to return colored cloud
function cloud {
    local PROXIED="$1"
    #if [[ ${PROXIED} == true ]]; then echo -e "${RY}${CLOUD}${N}"; else echo "${GR}${CLOUD}${N}"; fi
    if [[ ${PROXIED} == true ]]; then echo -e "${RY}${BULLET}${N}"; else echo "${GR}${BULLET}${N}"; fi
}

# function to lookup domains in list
function domain_lookup {
  local LIST="$1"
  local ITEM="$2"
  if [[ $LIST =~ (^|[[:space:]])"$ITEM"($|[[:space:]]) ]] ; then return 1; else return 0; fi
}

# Cloudflare API function (get/update/create)
function cfapi {
    ERROR=0
    DOMAIN=$1
    PROXY=true

    # remove
    #echo -e "$DOMAIN"
    
    if [[ ${DOMAIN} == *"_no_proxy"* ]];
    then
        DOMAIN=$(sed "s/_no_proxy/""/" <<< "$DOMAIN")
        PROXY=false
    fi
    API_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records?type=A&name=${DOMAIN}&page=1&per_page=100&match=all" \
        -H "Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json") || echo 0


    
    # remove

    echo -e "$API_RESPONSE"
    
    if [[ ${API_RESPONSE} == *"\"success\":false"* ]] && [[ ${API_RESPONSE} != *"\"success\":true"* ]] && [[ ${API_RESPONSE} != 0 ]];
    then
        ERROR=$(echo ${API_RESPONSE} | awk '{ sub(/.*"message":"/, ""); sub(/".*/, ""); print }')
        echo -e " ${CROSS_MARK} ${DOMAIN} => ${R}${ERROR}${N}\n"
        # remove
       # echo -e "$API_RESPONSE"
    fi

    if [[ ${API_RESPONSE} == 0 ]];
    then
        # test
        ITERATION=$(($ITERATION + 1))
        echo -e " ${CROSS_MARK} ${DOMAIN} => ${R}Failed to retrieve domain${N}"

        return
    fi
    
    if [[ "${API_RESPONSE}" == *'"count":0'* ]];
    then
        ERROR=1
        DATA=$(printf '{"type":"A","name":"%s","content":"%s","ttl":1,"proxied":%s}' "${DOMAIN}" "${PUBLIC_IP}" "${PROXY}")
        API_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records" \
            -H "Authorization: Bearer ${TOKEN}" \
            -H "Content-Type: application/json" \
            --data ${DATA})

        if [[ ${API_RESPONSE} == *"\"success\":false"* ]] && [[ ${API_RESPONSE} != *"\"success\":true"* ]];
        then
        
            # creation failed
            CREATION_ERRORS=$(($CREATION_ERRORS + 1))
            ERROR=$(echo ${API_RESPONSE} | awk '{ sub(/.*"message":"/, ""); sub(/".*/, ""); print }')
            echo -e " ${CROSS_MARK} ${DOMAIN} => ${R}${ERROR}${N}"
        else
        
            # creation successful (no need to mention current PIP (again))
            CREATION_COUNTER=$(($CREATION_COUNTER + 1))
            echo -e " $(cloud ${PROXY}) ${BG}${PLUS}${N} ${DOMAIN}"
        fi
    fi
    
    if [[ ${ERROR} == 0 ]];
    then
        DOMAIN_ID=$(echo ${API_RESPONSE} | awk '{ sub(/.*"id":"/, ""); sub(/",.*/, ""); print }')
        DOMAIN_IP=$(echo ${API_RESPONSE} | awk '{ sub(/.*"content":"/, ""); sub(/",.*/, ""); print }')
        DOMAIN_PROXIED=$(echo ${API_RESPONSE} | awk '{ sub(/.*"proxied":/, ""); sub(/,.*/, ""); print }')

        if [[ ${PUBLIC_IP} != ${DOMAIN_IP} ]];
        then
        
            # domain needs to be updated
            DATA=$(printf '{"type":"A","name":"%s","content":"%s","proxied":%s}' "${DOMAIN}" "${PUBLIC_IP}" "${DOMAIN_PROXIED}")
            API_RESPONSE=$(curl -sX PUT "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records/${DOMAIN_ID}" \
                -H "Authorization: Bearer ${TOKEN}" \
                -H "Content-Type: application/json" \
                --data ${DATA})

            if [[ ${API_RESPONSE} == *"\"success\":false"* ]] && [[ ${API_RESPONSE} != *"\"success\":true"* ]] ;
            then
            
                # update failed
                UPDATE_ERRORS=$(($UPDATE_ERRORS + 1))
                echo -e " $(cloud ${DOMAIN_PROXIED}) ${CROSS_MARK} ${DOMAIN}$(show_pip $DOMAIN_IP) => ${R}failed to update${N}"
            else
            
                # update successful
                UPDATE_COUNTER=$(($UPDATE_COUNTER + 1))
                echo -e " $(cloud ${DOMAIN_PROXIED}) ${RG}${RELOAD_SYMBOL}${N} ${DOMAIN}$(show_pip $DOMAIN_IP)"
             fi
        else
        
            # nothing changed
            echo -e " $(cloud ${DOMAIN_PROXIED}) ${DOMAIN}";
        fi
    fi
}

# starting message
if [[ ${INTERVAL} == 1 ]]; then echo -e "${RG}Iterating every minute${N}\n "; else echo -e "${RG}Iterating every ${INTERVAL} minutes${N}\n "; fi

while :
do
    SUCCESS=0
    SECONDS=0
    ISSUE=0

    #$(($ITERATION-$ITERATION_ERRORS)) <- successful iterations
    echo -e "Status: [${RG}${NEW_PIP_COUNTER}/${CREATION_COUNTER}/${UPDATE_COUNTER}${N}] [${RR}${PIP_ERRORS}/${ITERATION_ERRORS}/${CREATION_ERRORS}/${UPDATE_ERRORS}${N}]"
    echo -e "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    PIP_FETCH_START=`date +%s`
    
    # loop until PIP is known
    while :
    do
    
        # try different APIs to get current PIP
        for API in "ipify.org" "my-ip.io/ip"
        do PUBLIC_IP=$(curl -s --connect-timeout 5 https://api.$API || echo 0)
            if [[ $PUBLIC_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
            then
                SUCCESS=1
                break
            fi
        done
        
        if [[ $SUCCESS == 1 ]]
        then

            # retrieved PIP
            if [[ $PREVIOUS_PIP != "" ]] && [[ $PREVIOUS_PIP != $PUBLIC_IP ]]; then NEW_PIP_COUNTER=$(($NEW_PIP_COUNTER + 1)); fi
            PREVIOUS_PIP="$PUBLIC_IP"
            break
        fi

        # APIs failed to return PIP, retry in 10 seconds
        PIP_ERRORS=$(($PIP_ERRORS + 1))
        echo -e "${RR}Failed to get current public IP address. Retrying in 10 seconds...${N}"
        sleep 10s
    done
    
    # calculate next run time
    PIP_FETCH_TIME=$((`date +%s`-PIP_FETCH_START))
    if [[ ! $PIP_FETCH_TIME -ge $INTERVAL ]]; then PIP_FETCH_TIME=0; fi
    NEXT=$(echo | busybox date -d@"$(( `busybox date +%s`+(${INTERVAL}*60)-$PIP_FETCH_TIME ))" "+%Y-%m-%d %H:%M:%S")
    echo -e "Next: ${NEXT}"

    # print current PIP
    if [[ ${LOG_PIP} == true ]]; then echo -e "PIP: ${BB}${PUBLIC_IP}${N} by $(echo ${API} | cut -d '/' -f 1)"; fi
    
    # fetch existing A records
    DOMAINS=$(curl -sX GET "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records?type=A" \
        -H "Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json" | jq -r '.result[].name?' || echo 0)
    
    if [[ ! -z "$DOMAINS" ]] && [[ $DOMAINS != 0 ]];
    then
        count=$(wc -w <<< $PERSISTENT_DOMAINS)
        TMP_PERSISTENT_DOMAINS=$PERSISTENT_DOMAINS
        if [[ $count > 0 ]];
        then
        
            # add persistent domains to obtained record list
            for DOMAIN in ${TMP_PERSISTENT_DOMAINS[@]};
            do
                TMP_DOMAIN=$(sed "s/_no_proxy/""/" <<< "$DOMAIN")
                DOMAINS=( "${DOMAINS[@]/$DOMAIN/}" )
                if `domain_lookup "$DOMAINS" "$TMP_DOMAIN"`; then DOMAINS+=("$DOMAIN"); fi
            done
        fi
        
        # sort domain list alphabetically
        DOMAIN_LIST=($(for DOMAIN in "${DOMAINS[@]}"; do echo "${DOMAIN}"; done | sort -u))
        if [[ ! -z "$DOMAIN_LIST" ]];
        then
        
            # iterate through listed domains
            ITERATION=$(($ITERATION + 1))
            if [[ ${#DOMAIN_LIST[@]} == 1 ]]; then DOMAIN_COUNT="${#DOMAIN_LIST[@]} domain"; else DOMAIN_COUNT="${#DOMAIN_LIST[@]} domains"; fi
            echo "Iteration ${ITERATION}, ${DOMAIN_COUNT}:"
            for DOMAIN in ${DOMAIN_LIST[@]}; do cfapi ${DOMAIN}; done
        else
        
            # iteration failed
            ITERATION_ERRORS=$(($ITERATION_ERRORS + 1))
            echo -e "${RR}Inner domain list iteration failed. Restarting iteration in 60 seconds...${N}"
            ISSUE=1
        fi
    else
    
        # iteration failed
        ITERATION_ERRORS=$(($ITERATION_ERRORS + 1))
        echo -e "${RR}Outer domain list iteration failed. Restarting iteration in 60 seconds...${N}"
        ISSUE=1
    fi
    
    # set sleep time and wait until next iteration
    sleep $(if [[ $ISSUE == 1 ]]; then echo 60; else if [[ $(((($INTERVAL*60)-($SECONDS/60))-($SECONDS%60))) <= 1 ]]; echo -e $INTERVAL; else echo -e $(((($INTERVAL*60)-($SECONDS/60))-($SECONDS%60))); fi)s
    echo -e "\n "
done
