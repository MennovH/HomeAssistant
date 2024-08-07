#!/usr/bin/env bashio

declare BAN_FILE
declare BAN_LINE_COUNT_AFTER
declare BAN_LINE_COUNT_BEFORE
declare IP
declare INTERVAL

BAN_FILE="/config/ip_bans.yaml"
INTERVAL=$(bashio::config 'interval')
IPS=$(bashio::config "ip")

# font
N="\e[0m" #normal
I="\e[3m" #italic
S="\e[9m" #strikethrough
U="\e[4m" #underline

# colors
RG="\e[0;32m" #regular green
RR="\e[0;31m" #regular red
RY="\e[0;33m" #regular yellow
GR="\e[1;30m" #grey
BB="\e[1;34m" #bold blue
BG="\e[1;32m" #bold green
R="\e[1;31m" #bold red (error)

echo -e "🔓 Initializing add-on 🔓"

# checks on configuration
if [[ ${#IPS} == 0 ]];
then
    echo -e "${RR}Failed to run due to missing IPs${N}"
    exit 1
fi

if [[ ${INTERVAL} == 1 ]]; then echo -e "${RG}Iterating every minute${N}\n "; else echo -e "${RG}Iterating every ${INTERVAL} minutes${N}\n "; fi

function unban () {
    local IP=$1
    if [ -f "${BAN_FILE}" ];
    then
        if [[ $(grep -o "${IP}" "${BAN_FILE}" | wc -l) > 0 ]];
        then
            $(sed -e "/${IP}:/{N;N;d;}" "${BAN_FILE}" > "${BAN_FILE}");
            if [[ $(grep -o "${IP}" "${BAN_FILE}" | wc -l) == 0 ]];
            then
                echo -e "  > Unbanned IP ${IP}"
            fi
        fi
    fi
}

while :
do

    # calculate next run time
    echo -e "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    _START=`date +%s`

    _TIME=$((`date +%s`-_START))
    if [[ ! $_TIME -ge $INTERVAL ]]; then _TIME=0; fi
    NEXT=$(echo | busybox date -d@"$(( `busybox date +%s`+(${INTERVAL}*60)-$_TIME ))" "+%Y-%m-%d %H:%M:%S")

    # check ban file exists
    if [ -f "${BAN_FILE}" ];
    then
        BAN_LINE_COUNT_BEFORE=$(wc -l "${BAN_FILE}")
        for IP in ${IPS[@]}; do unban ${IP}; done
        BAN_LINE_COUNT_AFTER=$(wc -l "${BAN_FILE}")
        if ! [[ ${BAN_LINE_COUNT_BEFORE} == ${BAN_LINE_COUNT_AFTER} ]];
        then
            echo -e "${__BASHIO_COLORS_YELLOW}  > Restarting..${__BASHIO_COLORS_DEFAULT}"
            bashio::core.restart
            echo -e "${__BASHIO_COLORS_GREEN}  > Restarted${__BASHIO_COLORS_DEFAULT}"
        else
            echo -e "${__BASHIO_COLORS_GREEN}  > No IPs required removal${N}"
        fi
    else
        echo -e "File ${BAN_FILE} not found"
    fi
    
    echo -e "Next: ${NEXT}\n "
    # set sleep time and wait until next iteration
    sleep $(if [[ $(((($INTERVAL*60)-($SECONDS/60))-($SECONDS%60))) -le 1 ]]; then echo -e $INTERVAL; else echo -e $(((($INTERVAL*60)-($SECONDS/60))-($SECONDS%60))); fi)s
    
done
