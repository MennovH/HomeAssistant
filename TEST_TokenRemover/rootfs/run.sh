#!/usr/bin/env bashio

declare BAN_FILE
declare TMP_BAN_FILE
declare BAN_LINE_COUNT
declare TMP_BAN_LINE_COUNT

declare ACTIVATION_DAYS
declare KEEP_ACTIVE
declare RETENTION_DAYS
declare RESULT
declare AUTO

BAN_FILE="/config/ip_bans.yaml"
TMP_BAN_FILE="/config/tmp_ip_bans.yaml"
RETENTION_DAYS=$(bashio::config 'retention_days' | xargs echo -n)
KEEP_ACTIVE=$(bashio::config 'keep_active' | xargs echo -n)
ACTIVATION_DAYS=$(bashio::config 'activation_days' | xargs echo -n)
AUTOMATION=$(bashio::config 'automation' | xargs echo -n)
AUTOMATION_TIME=$(bashio::config 'automation_time' | xargs echo -n)
MON=$(bashio::config 'mon' | xargs echo -n)
TUE=$(bashio::config 'tue' | xargs echo -n)
WED=$(bashio::config 'wed' | xargs echo -n)
THU=$(bashio::config 'thu' | xargs echo -n)
FRI=$(bashio::config 'fri' | xargs echo -n)
SAT=$(bashio::config 'sat' | xargs echo -n)
SUN=$(bashio::config 'sun' | xargs echo -n)


if [ "${KEEP_ACTIVE}" == false ];
then
    echo -e " \nNote: You may get locked out for one minute after restart, as TokenRemover doesn't know which token belongs to whom. TokenRemover will restore the current ip_bans.yaml file when it detects newly banned IP addresses within one minute after execution. Home Assistant Core will then again be restarted to make this change permanent, after which you should be able to log in again.\n"
	ACTIVATION_DAYS = 999
    #RESULT=$(python3 run.py ${RETENTION_DAYS} 999)
#else
fi


run () {

    echo -e "Time: $(date '+%Y-%m-%d %H:%M:%S')\n"
	echo -e "Running TokenRemover\n"

	RESULT=$(python3 run.py ${RETENTION_DAYS} ${ACTIVATION_DAYS})

	echo -e " \n${RESULT}\n"
	if [[ ${RESULT} == *"restart"* ]];
	then
		if [ -f "${BAN_FILE}" ];
		then
			cp "${BAN_FILE}" "${TMP_BAN_FILE}"
			BAN_LINE_COUNT=$(wc -l "${BAN_FILE}")
		fi
		
		sleep 0.75
		
		curl -X DELETE -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/auth/cache >/dev/null 2>&1
		bashio::core.restart
		
		echo -e "(still) Running checks...\n"
		for i in {1..4};
		do
			sleep 15
		done

		if [ -f "${BAN_FILE}" ];
		then
			TMP_BAN_LINE_COUNT=$(wc -l "${BAN_FILE}")
			if ! [[ ${BAN_LINE_COUNT} == ${TMP_BAN_LINE_COUNT} ]];
			then
				echo -e "\e[1;31mDetected banned IP addresses since execution.\nRestoring ip_bans.yaml file.\e[1;37m\n"
				cp "${TMP_BAN_FILE}" "${BAN_FILE}" && rm "${TMP_BAN_FILE}"
				
				bashio::core.restart
				
				echo -e " \nFinished restoring ip_bans.yaml file.\n"
			else
				rm "${TMP_BAN_FILE}";
			fi
		fi
	fi

	echo "Finished TokenRemover execution"

}

INTERVAL=15


AUTO=false
for day in MON TUE WED THU FRI SAT SUN;
do
	echo -e "${day}"
	if [ "${day}" == true ];
	then
		AUTO=true
		echo "true"
		break
	fi
done


if [ "${AUTO}" == false ];
then
	AUTOMATION=false
fi


while :
do	
	if [ "${AUTOMATION}" == false ];
	then
		run
		break
	else
		
		RESULT=$(python3 get_date.py)
		sleep ${RESULT}
		
		run
	fi
	
done
