#!/usr/bin/env bashio

declare DAY
declare RESULT
declare BAN

BAN="/config/ip_bans.yaml"
DAY=$(bashio::config 'day' | xargs echo -n)

echo -e "Time: $(date '+%Y-%m-%d %H:%M:%S') > Running TokenRemover\n"
RESULT=$(python3 run.py ${DAY})

echo -e "${RESULT}\n"
if [[ ${RESULT} == *"restart"* ]];
then

    if [ -f "${BAN}" ];
    then
        cp /config/ip_bans.yaml /config/tmp_ip_bans.yaml   
    fi
    
    BANNUM=$(wc -l "${BAN}")
    
    sleep 0.75
    curl -X DELETE "http://supervisor/auth/cache" -H "Authorization: Bearer $SUPERVISOR_TOKEN"
    bashio::core.restart
    
    runtime="5 minute"
    endtime=$(date -ud "$runtime" +%s)

    while [[ $(date -u +%s) -le $endtime ]]
    do
        echo "Aftermath: `date +%H:%M:%S`"
        BANNUM2=$(wc -l "${BAN}")
        sleep 30
    done
    
    if [ -f "${BAN}" && ${BANNUM2} > ${BANNUM}];
    then
        cp /config/tmp_ip_bans.yaml /config/ip_bans.yaml && rm
        bashio::core.restart
    fi
fi

echo -e "Finished TokenRemover execution"
