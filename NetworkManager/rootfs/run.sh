#!/usr/bin/env bashio

declare CMD
declare RESTART
declare RELOAD_SYMBOL
declare BULLET
declare CROSS_MARK

# variables
CMD=$(bashio::config 'command'| xargs echo -n)
RESTART=$(bashio::config 'restart_networkmanager')
CROSS_MARK="\u274c"
PLUS="\uff0b"
BULLET="\u2022"
RELOAD_SYMBOL="\u21bb"


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
#if [[ ${#CMD} == 0 ]];
#then
#    echo -e "${RR}Failed to run due to missing Cloudflare Zone ID${N}"
#    exit 1
#elif [[ ${#TOKEN} == 0 ]];
#then
#    echo -e "${RR}Failed to run due to missing Cloudflare API token${N}"
#    exit 1
#fi


if [[ ${#CMD} != 0 ]];
then
	echo -e $($CMD)
fi

if [[ ${RESTART} == true ]]
then
	echo -e $(systemctl restart NetworkManager)
fi
