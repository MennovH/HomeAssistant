#!/usr/bin/env bashio

declare INTERNAL_IP
declare INTERNAL_PORT
declare TEST_METHOD
declare INTERVAL
declare FILENAME

INTERNAL_IP=$(bashio::config 'internal_ip_or_fqdn' | xargs echo -n)
INTERNAL_PORT=$(bashio::config 'internal_port')
TEST_METHOD=$(bashio::config 'test_method')
INTERVAL=$(bashio::config 'interval')
FILENAME="/config/configuration.yaml"

HTTPS=0
EXPIRED=1

echo -e "${INTERNAL_IP}"

while :
do
    echo -e "${TEST_METHOD}"
    if [[ ${TEST_METHOD} == "Connection" ]];
    then
        # check HTTPS connection
        # Get the final hostname because this URL might be redirected
        HTTPS=0
        HOST=$(curl "https://${INTERNAL_IP}" -Ls -o /dev/null -w %{url_effective} | awk -F[/:] '{ print $4 }')

        # Use openssl to get the status of the host
        TEST=$(echo | openssl s_client "${INTERNAL_IP}" -connect "${HOST}:${INTERNAL_PORT}" </dev/null 2>/dev/null | grep 'Verify return code: 0 (ok)')

        if [ -n "${TEST}" ];
        then
            HTTPS=1 #valid HTTPS
        fi

    elif [[ ${TEST_METHOD} == "Certificate" ]];
    then
        # check certificate expiration date
        # use openssl to request certificate and retrieve its expiration date
        EXPIRED=1
        
        echo "Testing certificate..."
        #echo -e $(openssl s_client -servername "${INTERNAL_IP}" -connect "${INTERNAL_IP}":"${INTERNAL_PORT}" 2>/dev/null | openssl x509 -noout -dates | grep -i notafter | cut -c 10-)
        TEST=$(echo | openssl s_client -servername "${INTERNAL_IP}" -connect "${INTERNAL_IP}:${INTERNAL_PORT}" 2>/dev/null | openssl x509 -noout -dates | grep -i notafter | cut -c 10-)

        echo -e "${TEST}"
        echo `date`

        if [[ $(date -d "${date}" +"%s") < $(date -d "${TEST}" +"%s") ]];
        then
            EXPIRED=0 #valid certificate
        fi
    fi
    
    # check number of occurrences
    cert=$(grep -c "ssl_certificate" $FILENAME)
    key=$(grep -c "ssl_key" $FILENAME)

    if [[ ${HTTPS} == 1 || ${EXPIRED} == 0 ]];
    then
       echo -e "Site ${INTERNAL_IP} with port ${INTERNAL_PORT} is valid https"
    elif [[ ${HTTPS} == 0 || ${EXPIRED} == 1 ]];
    then
       echo -e "Site ${INTERNAL_IP} with port ${INTERNAL_PORT} is not valid https"

       COUNTER=0
       HTTP=0
       LINES=$(cat ${FILENAME})

       while read -r LINE;
       do
           COUNTER=$((COUNTER+1))
           if [[ ${LINE} == *"http:"* ]];
           then
               HTTP=1
               continue
           elif [[ ${HTTP} == 0 ]];
           then
               continue
           fi
           if [[ (${LINE} == *"ssl_certificate"* && ! $LINE == *"#"*) \
                ||  ${LINE} == *"ssl_key"* && ! $LINE == *"#"* ]];
           then
               sed -i "${COUNTER}s/^/\#/" $FILENAME
           fi
       done < "$FILENAME"

       # reload Home Assistant
       #$(reboot now)

    fi

    if [[ ${INTERVAL} == 1 ]];
    then
        echo -e " \nWaiting 1 minute for next check...\n "
    else
        echo -e " \nWaiting ${INTERVAL} minutes for next check...\n "
    fi

    sleep ${INTERVAL}m

done
