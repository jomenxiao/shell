#!/bin/bash

STABILITY_TESTER=$1
DB_HOST_IP="$(echo $2 |awk -F ":" '{print $2}')"
DB_HOST_PORT="$(echo $3 |awk -F ":" '{print $2}')"
DB_USER="$(echo $4 |awk -F ":" '{print $2}')"
DB_PASSWORD="$(echo $5 |awk -F ":" '{print $2}')"

CONFIG_TOML_FILE=$6



if [[ ${STABILITY_TESTER} =~ "sysbench|sqllogic_test" ]];then
    sed -i  -e '/\[suite\]/{n;s/names.*/names = \[\]/}' \
        -e "/\[serial_suite\]/{n;s/names.*/names = \[ ${STABILITY_TESTER} \]/}" \
        
else
    sed -i  -e "/\[suite\]/{n;s/names.*/names = \[ ${STABILITY_TESTER} \]/}" \
        -e "/\[serial_suite\]/{n;s/names.*/names = \[ \]/}" \
        ${CONFIG_TOML_FILE}
fi


sed -i  -e "s/host.*/host = \"${DB_HOST_IP}\"/g" \
        -e "s/port.*/port = \"${DB_HOST_PORT}\"/g" \
        -e "s/user.*/user = \"${DB_USER}\"/g" \
        -e "s/password.*/password = \"${DB_PASSWORD}\"/g" \
            ${CONFIG_TOML_FILE}
