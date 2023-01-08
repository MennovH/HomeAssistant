#!/usr/bin/env bashio

declare DAY
declare RET

DAY=$(bashio::config 'day' | xargs echo -n)

echo -e "Running script\n"
RESULT=$(python3 run.py ${DAY})

echo -e "${RESULT}\n"
if [[ ${RESULT} == *"Restart"* ]];
then
    bashio::core.restart
fi
echo "Done"
