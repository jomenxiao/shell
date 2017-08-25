#!/bin/bash

STABILITY_TESTER=$1
CONFIG_TOML_FILE=$2


if [[ ${STABILITY_TESTER} =~ "sysbench|sqllogic_test" ]];then
    sed -i  -e '/\[suite\]/{n;s/names.*/names = \[\]/}' \
        -e "/\[serial_suite\]/{n;s/names.*/names = \[ ${STABILITY_TESTER} \]/}" \
        
else
    sed -i  -e "/\[suite\]/{n;s/names.*/names = \[ ${STABILITY_TESTER} \]/}" \
        -e "/\[serial_suite\]/{n;s/names.*/names = \[ \]/}" \
        ${CONFIG_TOML_FILE}
fi
