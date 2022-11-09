#!/usr/bin/env bashio
#!/usr/bin ha

declare INTERNAL_IP
declare INTERNAL_PORT
declare TEST_METHOD
declare INTERVAL
declare FILENAME
declare CURRENT_DATE

INTERNAL_IP=$(bashio::config 'internal_ip_or_fqdn' | xargs echo -n)
INTERNAL_PORT=$(bashio::config 'internal_port')
TEST_METHOD=$(bashio::config 'test_method')
INTERVAL=$(bashio::config 'interval')
FILENAME="/config/configuration.yaml"
CHECK_MARK="\033[0;32m\xE2\x9C\x94\033[0m"
HTTPS=0
EXPIRED=1

while :
do
    CURRENT_DATE=$(echo | date +'%s')
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
        
        echo "Testing certificate of host ${INTERNAL_IP}:${INTERNAL_PORT}..."
        TEST=$(echo | openssl s_client -servername "${INTERNAL_IP}" -connect "${INTERNAL_IP}:${INTERNAL_PORT}" 2>/dev/null | openssl x509 -noout -dates | grep -i notafter | cut -c 10- | sed 's/  / /g' | sed 's/ GMT//g')
        EXP_DATE=$(date -d "${TEST}" +"%s")

        if [[ "${CURRENT_DATE}" < "${EXP_DATE}" ]];
        then
            EXPIRED=0 #valid certificate
            echo -e " - \e[1;32mCertificate is valid until: ${TEST}\e[1;37m\n"
        else
            echo -e " - \e[1;31mCertificate has expired on: ${TEST}\e[1;37m\n"
        fi
    fi
    
    # check number of occurrences
    cert=$(grep -c "ssl_certificate" $FILENAME)
    key=$(grep -c "ssl_key" $FILENAME)

    #if [[ ${HTTPS} == 1 || ${EXPIRED} == 0 ]];
    if [[ 1 == 2 ]];
    then
       echo -e "Valid HTTPS"
    elif [[ ${HTTPS} == 0 || ${EXPIRED} == 1 ]];
    then
       echo -n "Updating configuration.yaml,..."
       
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

       echo -e "\\r${CHECK_MARK}"
       echo -e "Rebooting Hassio,..."

       # reload Home Assistant
       ha core restart
       #$(echo | ha core restart)
       echo -e "\\r${CHECK_MARK}\n"
       
    fi

    if [[ ${INTERVAL} == 1 ]];
    then
        echo -e " \nWaiting 1 minute for next check...\n "
    else
        echo -e " \nWaiting ${INTERVAL} minutes for next check...\n "
    fi

    sleep ${INTERVAL}m

done
