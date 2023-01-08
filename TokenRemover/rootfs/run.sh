#!/usr/bin/env bashio

declare HOUR
declare QUARTER
declare DAY

HOUR=$(bashio::config 'hour' | xargs echo -n)
QUARTER=$(bashio::config 'quarter' | xargs echo -n)
DAY=$(bashio::config 'day' | xargs echo -n)

while :
do
    at ${HOUR}:${QUARTER} /run.py ${DAY}
done
