#!/usr/bin/env bashio

declare DAY
declare RESULT

DAY=$(bashio::config 'day' | xargs echo -n)

echo -e "Time: $(date '+%Y-%m-%d %H:%M:%S') > Running TokenRemover\n"
RESULT=$(python3 run.py ${DAY})

echo -e "${RESULT}\n"
if [[ ${RESULT} == *"Removed"* ]];
then
    bashio::cache.flush_all
fi

echo -e "Finished TokenRemover execution"
