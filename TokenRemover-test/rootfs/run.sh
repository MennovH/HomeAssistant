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
declare ADDON
declare WEEKDAYS

BAN_FILE="/config/ip_bans.yaml"
TMP_BAN_FILE="/config/tmp_ip_bans.yaml"
RETENTION_DAYS=$(bashio::config 'retention_days' | xargs echo -n)
KEEP_ACTIVE=$(bashio::config 'keep_active' | xargs echo -n)
ACTIVATION_DAYS=$(bashio::config 'activation_days' | xargs echo -n)
AM_PM=$(bashio::config 'am_pm' | xargs echo -n)
AUTOMATION_TIME=$(bashio::config 'automation_time' |  sed 's/ .*//' | xargs echo -n)
WEEKDAYS=$(jq -n \
  --arg mon "$(bashio::config 'mon')" \
  --arg tue "$(bashio::config 'tue')" \
  --arg wed "$(bashio::config 'wed')" \
  --arg thu "$(bashio::config 'thu')" \
  --arg fri "$(bashio::config 'fri')" \
  --arg sat "$(bashio::config 'sat')" \
  --arg sun "$(bashio::config 'sun')" \
  '{
    mon: ($mon == "true"),
    tue: ($tue == "true"),
    wed: ($wed == "true"),
    thu: ($thu == "true"),
    fri: ($fri == "true"),
    sat: ($sat == "true"),
    sun: ($sun == "true")
  }'
)
AUTO="Once"
echo "$WEEKDAYS" | jq -e 'any(.[]; .)' > /dev/null && AUTO="Defined"

if [ "${KEEP_ACTIVE}" == false ];
then
    echo -e "${__BASHIO_COLORS_YELLOW}Note: You may get locked out for one minute after restart, as TokenRemover doesn't know which token belongs to whom. TokenRemover will restore the current ip_bans.yaml file when it detects newly banned IP addresses within one minute after execution. Home Assistant Core will then again be restarted to make this change permanent, after which you should be able to log in again.\n${__BASHIO_COLORS_DEFAULT}"
	ACTIVATION_DAYS = 999
fi

run () {

    echo -e " Time: $(date '+%Y-%m-%d %H:%M:%S')"	
	
	RESULT=$(python3 run.py 1 ${RETENTION_DAYS} ${ACTIVATION_DAYS})
	
	if [[ ${RESULT} == *"Restart"* ]];
	then
		if [ -f "${BAN_FILE}" ];
		then
			cp "${BAN_FILE}" "${TMP_BAN_FILE}"
			BAN_LINE_COUNT=$(wc -l "${BAN_FILE}")
		fi
		echo -e -n "${RESULT}"
		
		# sleep 0.75
		
		# restart Home Assistant Core
		# bashio::core.restart
		
		sleep 120
			
		if [ -f "${BAN_FILE}" ];
		then
			TMP_BAN_LINE_COUNT=$(wc -l "${BAN_FILE}")
			if ! [[ ${BAN_LINE_COUNT} == ${TMP_BAN_LINE_COUNT} ]];
			then
				echo -e "${__BASHIO_COLORS_YELLOW}  > Detected new IP bans${__BASHIO_COLORS_DEFAULT}\n    Restoring ip_bans.yaml file"
				cp "${TMP_BAN_FILE}" "${BAN_FILE}" && rm "${TMP_BAN_FILE}"
				
				bashio::core.restart
				
				echo -e "${__BASHIO_COLORS_GREEN}  > Restored ip_bans.yaml file${__BASHIO_COLORS_DEFAULT}"
			else
				rm "${TMP_BAN_FILE}";
			fi
		fi
	else
		echo -e "${RESULT}"
	fi
	echo -e "  > Finished TokenRemover execution\n "
}

if [ "${AUTO}" == "Once" ];
then
	echo -e "${__BASHIO_COLORS_YELLOW}TokenRemover will run only once due to invalid recurrence configuration${__BASHIO_COLORS_DEFAULT}"
	
	# Get current addon name
 	#echo 1
	ADDON=$(curl -X GET --silent -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/addons)
	ADDON=$(python3 run.py 2 ${ADDON})
	run

 	#echo 2
	# Permanently stop this addon from running
	$(curl -X POST --silent -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/addons/${ADDON}/stop > /dev/null 2>&1)
	
else
	echo -e "${__BASHIO_COLORS_GREEN}TokenRemover will run at set times${__BASHIO_COLORS_DEFAULT}\n "
	while :
	do
		# RESULT=$(python3 run.py 0 ${AM_PM} ${AUTOMATION_TIME} ${WEEKDAYS})
		RESULT=$(python3 run.py 0 "${AM_PM}" "${AUTOMATION_TIME}" "${WEEKDAYS}")

		echo -e $(echo -e "${RESULT}" | head -n1)
		sleep $(echo -e "${RESULT}" | tail -n1)
		
		run
		sleep 60	
	done
fi
