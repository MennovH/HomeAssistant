#!/usr/bin/env bashio

declare DAY
declare RESULT
declare BAN

BAN="/config/ip_bans.yaml"
TMP_BAN="/config/tmp_ip_bans.yaml"
DAY=$(bashio::config 'day' | xargs echo -n)

echo -e "Time: $(date '+%Y-%m-%d %H:%M:%S') > Running TokenRemover\n"
RESULT=$(python3 run.py ${DAY})

echo -e "${RESULT}\n"
if [[ ${RESULT} == *"restart"* ]];
then
    if [ -f "${BAN}" ];
    then
        cp "${BAN}" "${TMP_BAN}"
        BANNUM=$(wc -l "${BAN}")
    fi
    
    sleep 0.75
    curl -X DELETE "http://supervisor/auth/cache" -H "Authorization: Bearer $SUPERVISOR_TOKEN" >/dev/null 2>&1
    bashio::core.restart
    
    echo -e "Running checks...\n"
    for i in {1..3};
    do
        sleep 30
    done

    if [ -f "${BAN}" ];
    then
        BANNUM2=$(wc -l "${BAN}")
        if ! [[ ${BANNUM} == ${BANNUM2} ]];
        then
            echo -e "Detected banned IP addresses since execution.\nRestoring ip_bans.yaml file.\n"
            cp "${TMP_BAN}" "${BAN}" && rm "${TMP_BAN}"
            
            bashio::core.restart
            
            echo -e "Finished restoring ip_bans.yaml file.\n"
        else
            rm "${TMP_BAN}";
        fi
    fi
fi

echo "Finished TokenRemover execution"
