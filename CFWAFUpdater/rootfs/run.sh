#!/usr/bin/env bashio

declare TOKEN
declare ZONE
declare INTERVAL
declare LOG_PIP
declare RELOAD_SYMBOL
declare CROSS_MARK

# variables
TOKEN=$(bashio::config 'cloudflare_api_token'| xargs echo -n)
ZONE=$(bashio::config 'cloudflare_zone_id'| xargs echo -n)
EXPRESSION=$(bashio::config "expression")
RULESET=$(bashio::config "ruleset")
RULE_ID=$(bashio::config "ruleid")
INTERVAL=$(bashio::config 'interval')
LOG_PIP=$(bashio::config 'log_pip')

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
API1=0
API2=0

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

# starting message
if [[ ${INTERVAL} == 1 ]]; then echo -e "${RG}Iterating every minute${N}\n "; else echo -e "${RG}Iterating every ${INTERVAL} minutes${N}\n "; fi

while :
do
    SUCCESS=0
    SECONDS=0
    ISSUE=0

    echo -e "Status: [${RG}${NEW_PIP_COUNTER}/${CREATION_COUNTER}/${UPDATE_COUNTER}${N}] [${RR}${PIP_ERRORS}/${ITERATION_ERRORS}/${CREATION_ERRORS}/${UPDATE_ERRORS}${N}]"
    echo -e "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    PIP_FETCH_START=`date +%s`
    
    # loop until PIP is known
    while :
    do

        # try different APIs to get current PIP
        for API in "ipify.org" "my-ip.io/ip"
        do PUBLIC_IP=$(wget -O - -q -t 1 https://api.$API 2>/dev/null || echo 0)
            # do PUBLIC_IP=$((curl -s --connect-timeout 5 https://api.$API) || echo 0) //old
            if [[ $PUBLIC_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
            then
                SUCCESS=1
                if [[ $API == 'ipify.org' ]];
                then
                    API1=$(($API1 + 1));
                else
                    API2=$(($API2 + 1));
                fi
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

    if [[ ${LOG_PIP} == true ]]; then echo -e "PIP: ${BB}${PUBLIC_IP}${N} by $(echo ${API} | cut -d '/' -f 1)"; fi
    
    set TMP_EXPRESSION=%$EXPRESSION:XXX.XXX.XXX.XXX=$PUBLIC_IP% 
    $(curl --request PATCH https://api.cloudflare.com/client/v4/zones/$ZONE/rulesets/$RULE_SET/rules/$RULE_ID --header "Authorization: Bearer $TOKEN" --header "Content-Type: application/json" --data '{
      "action": "skip",
      "expression": "' + $TMP_EXPRESSION + ')",
      "description": "No mTLS",
            "action_parameters": {
              "ruleset": "current",
              "phases": [
                "http_ratelimit",
                "http_request_firewall_managed",
                "http_request_sbfm"
              ]
            }
    
    }')
    
    # set sleep time and wait until next iteration
    #sleep $(if [[ $ISSUE == 1 ]]; then echo 60; elif [[ $(((($INTERVAL*60)-($SECONDS/60))-($SECONDS%60))) -le 1 ]]; then echo -e $INTERVAL; else echo -e $(((($INTERVAL*60)-($SECONDS/60))-($SECONDS%60))); fi)s
    sleep $(if [[ $(((($INTERVAL*60)-($SECONDS/60))-($SECONDS%60))) -le 1 ]]; then echo -e $INTERVAL; else echo -e $(((($INTERVAL*60)-($SECONDS/60))-($SECONDS%60))); fi)s
    echo -e "\n "
done
