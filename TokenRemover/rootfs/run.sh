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
        BANNUM=$(wc -l "${BAN}")
    fi
    
    sleep 0.75
    # delete auth cache
    curl -X DELETE "http://supervisor/auth/cache" -H "Authorization: Bearer $SUPERVISOR_TOKEN" >/dev/null 2>&1
    
    # invoke restart of Home Assistant Core
    bashio::core.restart

    # run the following procedure to re-enable locked out users after running TokenRemover
    # this could happen when [multiple] devices try to re-authenticate to Home Assistant with a revoked token
    # e.g. when "Keep me logged in" was set
    echo "Aftermath: `date +%H:%M:%S`"
    for i in {1..3}; do
        sleep 30
    done
    
    if [ -f "${BAN}" ];
    then
        if [[ ${BANNUM} != $(wc -l "${BAN}") ]];
        then
            echo -e "${BANNUM}"
            echo -e $(wc -l "${BAN}")
            # restore ip_bans.yaml file, restart ha core again to make changes persistent
            echo "Detected banned IP addresses since execution.\nRestoring ip_bans.yaml file."
            cp /config/tmp_ip_bans.yaml /config/ip_bans.yaml && rm /config/tmp_ip_bans.yaml
            bashio::core.restart
        else
            # remove temporary ip_bans.yaml file
            rm /config/tmp_ip_bans.yaml
    fi
fi

echo -e "Finished TokenRemover execution"
