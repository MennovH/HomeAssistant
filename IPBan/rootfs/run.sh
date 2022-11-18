#!/usr/bin/env bashio

declare INTERVAL
declare ALLOW
declare FILENAME
declare CHECK_MARK

INTERVAL=$(bashio::config 'interval')
ALLOW=$(bashio::config 'allow')
FILENAME="/config/ip_bans.yaml"
CHECK_MARK="\033[0;32m\xE2\x9C\x94\033[0m"

echo -e "${FILENAME}"
while :
do
    CURRENT_DATE=$(echo | date +'%s')

    while IFS= read -r line;
    do
        printf '%s\n' "$line"
        # if should be allowed...
    done < ${FILENAME}

    if [[ ${INTERVAL} == 1 ]];
    then
        echo -e " \nWaiting 1 minute for next check...\n "
    else
        echo -e " \nWaiting ${INTERVAL} minutes for next check...\n "
    fi

    sleep ${INTERVAL}m

done
