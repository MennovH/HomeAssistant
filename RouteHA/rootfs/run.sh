#!/usr/bin/env bashio

declare GATEWAY
declare ROUTES
declare INTERVAL

# variables
GATEWAY=$(bashio::config 'gateway'| xargs echo -n)
ROUTES=$(bashio::config "static_routes")
INTERVAL=$(bashio::config 'interval')

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

echo -e "Initializing add-on"

# checks on configuration
if [[ ${#DEFAULT} == 0 ]];
then
    echo -e "${RR}Failed to run due to missing default route${N}"
    exit 1
fi

# starting message
if [[ ${INTERVAL} == 1 ]]; then echo -e "${RG}Iterating every minute${N}\n "; else echo -e "${RG}Iterating every ${INTERVAL} minutes${N}\n "; fi

while :
do

    echo -e "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    RUN_START=`date +%s`
    
    #get route table
    ROUTETABLE=$(ip route)
    echo -e "Route table:\n${ROUTETABLE}"

    ip route | while IFS= read -r line; do if [[ $line == *"default via $GATEWAY"* ]]; then echo $line - yes; else echo $line - no; fi; done
    
    # calculate next run time
    RUN_START_TIME=$((`date +%s`-RUN_START))
    if [[ ! $RUN_START_TIME -ge $INTERVAL ]]; then RUN_START_TIME=0; fi
    NEXT=$(echo | busybox date -d@"$(( `busybox date +%s`+(${INTERVAL}*60)-$RUN_START_TIME ))" "+%Y-%m-%d %H:%M:%S")
    echo -e "Next: ${NEXT}"

    
    # set sleep time and wait until next iteration
    sleep $(if [[ $(((($INTERVAL*60)-($SECONDS/60))-($SECONDS%60))) -le 1 ]]; then echo -e $INTERVAL; else echo -e $(((($INTERVAL*60)-($SECONDS/60))-($SECONDS%60))); fi)s
    echo -e "\n "
done
