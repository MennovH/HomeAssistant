#!/usr/bin/env bashio

declare DAY
declare RESULT
declare BAN
declare LAST_USED 

declare ACTIVE_DAYS
BAN="/config/ip_bans.yaml"
TMP_BAN="/config/tmp_ip_bans.yaml"
RETENTION_DAYS=$(bashio::config 'retention_days' | xargs echo -n)
LAST_USED=$(bashio::config 'last_used' | xargs echo -n)
ACTIVE_DAYS=$(bashio::config 'active_days' | xargs echo -n)

echo -e "Time: $(date '+%Y-%m-%d %H:%M:%S')\n"
echo -e "Running TokenRemover\n\n\nNote: You may get locked out for one minute after restart, as TokenRemover doesn't know which token belongs to whom. TokenRemover will restore the current ip_bans.yaml file when it detects newly banned IP addresses after execution. Home Assistant Core will then again be restarted to make this change permanent, after which you should be able to log in again.\n\n\n"

if [ "${LAST_USED}" == false ];
then
    RESULT=$(python3 run.py ${RETENTION_DAYS} 999)
else
    RESULT=$(python3 run.py ${RETENTION_DAYS} ${ACTIVE_DAYS})
fi

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
    
    echo -e "(still) Running checks...\n"
    for i in {1..4};
    do
        sleep 15
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
