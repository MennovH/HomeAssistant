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

unban () {
    ERROR=0
    IP=$1
    if [ -f "${BAN_FILE}" ];
    then
        if [ $(grep -o "${IP}" "${BAN_FILE}" | wc -l) > 0 ];
        then
            $(sed -e "/${IP}:/{N;N;d;}" "${BAN_FILE}" > "${BAN_FILE}");
            if [ $(grep -o "${IP}" "${BAN_FILE}" | wc -l) == 0 ];
            then
                echo -e "  > Removed ${IP} from ban file\n "
            fi
        fi
    fi
}


if [[ ${INTERVAL} == 1 ]]; then echo -e "${RG}Iterating every minute${N}\n "; else echo -e "${RG}Iterating every ${INTERVAL} minutes${N}\n "; fi

while :
do

    # calculate next run time
    START_TIME=$((`date +%s`-PIP_FETCH_START))
    if [[ ! $START_TIME -ge $INTERVAL ]]; then START_TIME=0; fi
    NEXT=$(echo | busybox date -d@"$(( `busybox date +%s`+(${INTERVAL}*60)-$START_TIME ))" "+%Y-%m-%d %H:%M:%S")
    echo -e "Next: ${NEXT}"

    if [ -f "${BAN_FILE}" ];
    then
        BAN_LINE_COUNT_BEFORE=$(wc -l "${BAN_FILE}")
        for IP in ${IPS[@]}; do unban ${IP}; done
        BAN_LINE_COUNT_AFTER=$(wc -l "${BAN_FILE}")
        if ! [[ ${BAN_LINE_COUNT_BEFORE} != ${BAN_LINE_COUNT_AFTER} ]];
        then
            echo -e "${__BASHIO_COLORS_YELLOW}  > Removed trusted IPs from ip_bans.yaml file, restarting..${__BASHIO_COLORS_DEFAULT}\n"
            
            bashio::core.restart
            
            echo -e "${__BASHIO_COLORS_GREEN}  > Restarted${__BASHIO_COLORS_DEFAULT}"

        fi
    fi
    
    # set sleep time and wait until next iteration
    sleep $(if [[ $(((($INTERVAL*60)-($SECONDS/60))-($SECONDS%60))) -le 1 ]]; then echo -e $INTERVAL; else echo -e $(((($INTERVAL*60)-($SECONDS/60))-($SECONDS%60))); fi)s
    echo -e "\n "
done

