#!/usr/bin/env bashio

declare DAY
declare RESULT

DAY=$(bashio::config 'day' | xargs echo -n)

echo -e "Time: $(date '+%Y-%m-%d %H:%M:%S') > Running TokenRemover\n"
RESULT=$(python3 run.py ${DAY})

echo -e "${RESULT}\n"
if [[ ${RESULT} == *"restart"* ]];
then
    sleep 0.75
    bashio::core.restart
fi

echo -e "Finished TokenRemover execution"
