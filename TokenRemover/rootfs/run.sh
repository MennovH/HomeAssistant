#!/usr/bin/env bashio

declare DAY
declare RESULT
declare BAN

BAN = "/config/ip_bans.yamls"
DAY=$(bashio::config 'day' | xargs echo -n)

echo -e "Time: $(date '+%Y-%m-%d %H:%M:%S') > Running TokenRemover\n"
RESULT=$(python3 run.py ${DAY})

echo -e "${RESULT}\n"
if [[ ${RESULT} == *"restart"* ]];
then

    if [ -f ${BAN} ];
    then
        cp /config/ip_bans.yaml /config/tmp_ip_bans.yaml   
    fi
    
    sleep 0.75
    curl -X DELETE "http://supervisor/auth/cache" -H "Authorization: Bearer $SUPERVISOR_TOKEN"
    bashio::core.restart
    
    if [ -f ${BAN} ];
    then
        cp /config/tmp_ip_bans.yaml /config/ip_bans.yaml && rm 
    fi
fi

echo -e "Finished TokenRemover execution"
