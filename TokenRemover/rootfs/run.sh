#!/usr/bin/env bashio

#declare HOUR
#declare QUARTER
declare DAY
declare RET

#HOUR=$(bashio::config 'hour' | xargs echo -n)
#QUARTER=$(bashio::config 'quarter' | xargs echo -n)
DAY=$(bashio::config 'day' | xargs echo -n)

echo "Running script\n"
RESULT=$(python3 run.py ${DAY})

echo -e "${RESULT}\n"

if [[ ${RESULT} == *"Restart"* ]];
then
    bashio::core.restart
fi
echo "Done"
