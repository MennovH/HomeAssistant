#!/usr/bin/env bashio

#declare HOUR
#declare QUARTER
declare DAY

#HOUR=$(bashio::config 'hour' | xargs echo -n)
#QUARTER=$(bashio::config 'quarter' | xargs echo -n)
DAY=$(bashio::config 'day' | xargs echo -n)

echo "Running script"
python3 /run.py ${DAY}
echo "Done"

#bashio::core.restart
#while :
#do

	#echo -e "/run.py ${DAY}" | at ${HOUR}:${QUARTER}
	#at -f /run.py ${DAY} ${HOUR}:${QUARTER}
	#NEXT=$(echo | busybox date -d@"$(( `busybox date +%s`+86400 ))" "+%Y-%m-%d %H:%M:%S")
    	#echo -e " \nNext check is at ${NEXT}\n "
    	#sleep 86400m
#done
