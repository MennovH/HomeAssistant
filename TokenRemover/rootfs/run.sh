#!/usr/bin/env bashio

declare DAY
declare RESULT
declare BAN
declare LAST_USED
declare KEEP_ACTIVE
declare ACTIVE_DAYS
declare ACTIVATION_DAYS
declare RETENTION_DAYS


BAN="/config/ip_bans.yaml"
TMP_BAN="/config/tmp_ip_bans.yaml"
#DAY=$(bashio::config 'day' | xargs echo -n)



if [[ -v $(bashio::config)["day"] ]];
then
    RETENTION_DAYS=$(bashio::config 'day' | xargs echo -n)
    # codeDict has ${STR_ARRAY[2]} as a key
else
    # codeDict does not have ${STR_ARRAY[2]} as a key
    RETENTION_DAYS=$(bashio::config 'retention_days' | xargs echo -n)
fi

if [[ -v $(bashio::config)["last_used"] ]];
then
    KEEP_ACTIVE=$(bashio::config 'last_used' | xargs echo -n)
    # codeDict has ${STR_ARRAY[2]} as a key
else
    # codeDict does not have ${STR_ARRAY[2]} as a key
    KEEP_ACTIVE=$(bashio::config 'keep_active' | xargs echo -n)
fi

if [[ -v $(bashio::config)["last_used"] ]];
then
    ACTIVATION_DAYS=$(bashio::config 'last_used' | xargs echo -n)
    # codeDict has ${STR_ARRAY[2]} as a key
else
    # codeDict does not have ${STR_ARRAY[2]} as a key
    ACTIVATION_DAYS=$(bashio::config 'activation_days' | xargs echo -n)
fi

#LAST_USED=$(bashio::config 'last_used' | xargs echo -n)
#ACTIVE_DAYS=$(bashio::config 'active_days' | xargs echo -n)

echo -e "Time: $(date '+%Y-%m-%d %H:%M:%S')\n"
echo -e "Running TokenRemover\n"
echo -e " \nNote: You may get locked out for one minute after restart, as TokenRemover doesn't know which token belongs to whom. TokenRemover will restore the current ip_bans.yaml file when it detects newly banned IP addresses after execution. Home Assistant Core will then again be restarted to make this change permanent, after which you should be able to log in again.\n"

if [ "${KEEP_ACTIVE}" == false ];
then
    RESULT=$(python3 run.py ${RETENTION_DAYS} 999)
else
    RESULT=$(python3 run.py ${RETENTION_DAYS} ${ACTIVATION_DAYS})
fi

echo -e " \n${RESULT}\n"
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
            echo -e "\e[1;31mDetected banned IP addresses since execution.\nRestoring ip_bans.yaml file.\e[1;37m\n"
            cp "${TMP_BAN}" "${BAN}" && rm "${TMP_BAN}"
            
            bashio::core.restart
            
            echo -e " \nFinished restoring ip_bans.yaml file.\n"
        else
            rm "${TMP_BAN}";
        fi
    fi
fi

echo "Finished TokenRemover execution"
