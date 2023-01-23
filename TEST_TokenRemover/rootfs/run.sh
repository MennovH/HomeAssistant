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
declare MON
declare TUE
declare WED
declare THU
declare FRI
declare SAT
declare SUN


BAN_FILE="/config/ip_bans.yaml"
TMP_BAN_FILE="/config/tmp_ip_bans.yaml"
RETENTION_DAYS=$(bashio::config 'retention_days' | xargs echo -n)
KEEP_ACTIVE=$(bashio::config 'keep_active' | xargs echo -n)
ACTIVATION_DAYS=$(bashio::config 'activation_days' | xargs echo -n)
AM_PM=$(bashio::config 'am_pm' | xargs echo -n)
AUTOMATION_TIME=$(bashio::config 'automation_time' | xargs echo -n)
MON=$(bashio::config 'mon' | xargs echo -n)
TUE=$(bashio::config 'tue' | xargs echo -n)
WED=$(bashio::config 'wed' | xargs echo -n)
THU=$(bashio::config 'thu' | xargs echo -n)
FRI=$(bashio::config 'fri' | xargs echo -n)
SAT=$(bashio::config 'sat' | xargs echo -n)
SUN=$(bashio::config 'sun' | xargs echo -n)

echo -e "${__BASHIO_COLORS_GREEN}Started add-on\n ${__BASHIO_COLORS_DEFAULT}"

if [ "${KEEP_ACTIVE}" == false ];
then
    echo -e " \nNote: You may get locked out for one minute after restart, as TokenRemover doesn't know which token belongs to whom. TokenRemover will restore the current ip_bans.yaml file when it detects newly banned IP addresses within one minute after execution. Home Assistant Core will then again be restarted to make this change permanent, after which you should be able to log in again.\n"
	ACTIVATION_DAYS = 999
fi


AUTO="Once"
for day in "${MON}" "${TUE}" "${WED}" "${THU}" "${FRI}" "${SAT}" "${SUN}";
do
	if [ "${day}" == true ];
	then
		AUTO="Defined"
		break
	fi
done

run () {

    echo -e " \nRun time: $(date '+%Y-%m-%d %H:%M:%S')\n"

	RESULT=$(python3 run.py 1 ${RETENTION_DAYS} ${ACTIVATION_DAYS})
	echo -e "${RESULT}\n"
	
	if [[ ${RESULT} == *"restart"* ]];
	then
		if [ -f "${BAN_FILE}" ];
		then
			cp "${BAN_FILE}" "${TMP_BAN_FILE}"
			BAN_LINE_COUNT=$(wc -l "${BAN_FILE}")
		fi
		
		sleep 0.75
		
		# restart Home Assistant Core
		bashio::core.restart
		
		echo -e "Running checks ..."
		
		sleep 60

		if [ -f "${BAN_FILE}" ];
		then
			TMP_BAN_LINE_COUNT=$(wc -l "${BAN_FILE}")
			if ! [[ ${BAN_LINE_COUNT} == ${TMP_BAN_LINE_COUNT} ]];
			then
				echo -e "\e[1A\e[\e[1;31mDetected banned IP addresses since execution.\nRestoring ip_bans.yaml file.\e[1;37m\n"
				cp "${TMP_BAN_FILE}" "${BAN_FILE}" && rm "${TMP_BAN_FILE}"
				
				bashio::core.restart
				
				echo -e " \nFinished restoring ip_bans.yaml file.\n"
			else
				rm "${TMP_BAN_FILE}";
			fi
		fi
	fi

	echo -e " -> Finished TokenRemover execution\n "

}

if [ "${AUTO}" == "Once" ];
then
	echo "${__BASHIO_COLORS_ORANGE}TokenRemover will run only once due to invalid recurrence configuration${__BASHIO_COLORS_DEFAULT}"
	run
else
	while :
	do
		RESULT=$(python3 run.py 0 ${AM_PM} ${AUTOMATION_TIME} ${MON} ${TUE} ${WED} ${THU} ${FRI} ${SAT} ${SUN})
		echo -e $(echo -e "${RESULT}" | head -n1)
		sleep $(echo -e "${RESULT}" | tail -n1)
		
		run
		sleep 60	
	done
fi
