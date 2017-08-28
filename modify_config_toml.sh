#!/bin/bash
#use : ./modify_config_toml.sh case db_host_ip:10.0.0.1 db_host_port:3306 db_user:root db_password:   config.toml

STABILITY_TESTER=$1
TIDB_IMAGE=$2
TIKV_IMAGE=$3
PD_IMAGE=$4
CLOUD_MANAGER_ADDR=$5
DIR_NAME_DATE=$6
MANAGER_OPERATOR=$7

CONFIG_TOML_FILE=$8

if [[ ${MANAGER_OPERATOR} == "create" ]];then
    chmod +x manager
    ./manager \
        -cmd create \
        -cloud-manager-addr "${CLOUD_MANAGER_ADDR}" \
        -tidb-version "${TIDB_IMAGE}" \
        -tikv-version "${TIKV_IMAGE}" \
        -pd-version "${PD_IMAGE}" \
        -name "${DIR_NAME_DATE}" \
        >tidb_info

    db_host_ip=$(head -n 1 tidb_info   |awk '{print $2}')
    db_host_port=$(head -n 2 tidb_info |tail -n 1 |awk '{print $2}')
    db_host_user="root"
    db_host_password=""
    if [[ ${STABILITY_TESTER} =~ sysbench|sqllogic_test ]];then
        sed -i  -e '/\[suite\]/{n;s/names.*/names = \[\]/}' \
            -e "/\[serial_suite\]/{n;s/names.*/names = \[ \"${STABILITY_TESTER}\" \]/}" \
            "${CONFIG_TOML_FILE}"
    else
        sed -i  -e "/\[suite\]/{n;s/names.*/names = \[ \"${STABILITY_TESTER}\" \]/}" \
            -e "/\[serial_suite\]/{n;s/names.*/names = \[ \]/}" \
            "${CONFIG_TOML_FILE}"
    fi
    sed -i  -e "s/host.*/host = \"${db_host_ip}\"/g" \
        -e "s/port.*/port = \"${db_host_port}\"/g" \
        -e "s/user.*/user = \"${db_host_user}\"/g" \
        -e "s/password.*/password = \"${db_host_password}\"/g" \
        "${CONFIG_TOML_FILE}"
elif [[ ${MANAGER_OPERATOR} == "delete" ]];then
    ./manager -name "${DIR_NAME_DATE}" -cmd delete

else
    echo "error params $*"
fi
