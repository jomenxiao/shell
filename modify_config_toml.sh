#!/bin/bash
#use : ./modify_config_toml.sh case tidb_image tikv_image pd_image cloud_manger_addr dir_name_date manager_operateor node config.toml

STABILITY_TESTER=$1
TIDB_IMAGE=$2
TIKV_IMAGE=$3
PD_IMAGE=$4
CLOUD_MANAGER_ADDR=$5
DIR_NAME_DATE="${6//_/-}"
MANAGER_OPERATOR=$7
MANAGER_LABEL=$8
CONFIG_TOML_FILE=$9


TIDB_COUNT=1
PD_COUNT=1
TIKV_COUNT=5

#if [[ $# -ne 8 ]];then
#    echo "error params number,it's 8"
#    exit -1
#fi

if [[ ${MANAGER_OPERATOR} == "create" ]];then
    chmod +x manager
    ./manager \
        -cmd create \
        -cloud-manager-addr "${CLOUD_MANAGER_ADDR}" \
        -tidb-version "${TIDB_IMAGE}" \
        -tikv-version "${TIKV_IMAGE}" \
        -pd-version "${PD_IMAGE}" \
        -name "${DIR_NAME_DATE}" \
        -tidb-count ${TIDB_COUNT} \
        -pd-count ${PD_COUNT} \
        -tikv-count ${TIKV_COUNT} \
        -label ${MANAGER_LABEL} \
        >tidb_info
    manager_exit=$?
    if [ ${manager_exit} -ne 0 ];then
        echo "can not create tidb cluster"
        cat tidb_info
        exit -2
    fi
    db_host_ip=$(grep "host:" tidb_info   |awk '{print $2}')
    db_host_port=$(grep "port:" tidb_info |tail -n 1 |awk '{print $2}')
    db_host_user="root"
    db_host_password=""

    sed -i  -e '/\[suite\]/{n;s/names.*/names = \[\]/}' \
        -e "/\[serial_suite\]/{n;s/names.*/names = \[\]/}" \
        "${CONFIG_TOML_FILE}"
    for _STABILITY_TESTER in ${STABILITY_TESTER//---/  }
    do
        if [[ ${_STABILITY_TESTER} =~ sysbench|sqllogic_test ]];then
            sed -i  \
                -e "/\[serial_suite\]/{n;s/names.*=.*\[.*\".*\"/&\,\"${_STABILITY_TESTER}\"/}" \
                "${CONFIG_TOML_FILE}"
            sed -i  \
                -e "/\[serial_suite\]/{n;s/names.*=.*\[\]/names = \[\"${_STABILITY_TESTER}\"\]/}" \
                "${CONFIG_TOML_FILE}"
        else
            sed -i \
                -e "/\[suite\]/{n;s/names.*=.*\[.*\".*\"/&\,\"${_STABILITY_TESTER}\"/}" \
                "${CONFIG_TOML_FILE}"
            sed -i \
                -e "/\[suite\]/{n;s/names.*=.*\[\]/names = \[ \"${_STABILITY_TESTER}\" \]/}" \
                "${CONFIG_TOML_FILE}"
        fi
    done
    sed -i  -e "s/host.*/host = \"${db_host_ip}\"/g" \
        -e "s/port.*/port = ${db_host_port}/g" \
        -e "s/user.*/user = \"${db_host_user}\"/g" \
        -e "s/password.*/password = \"${db_host_password}\"/g" \
        "${CONFIG_TOML_FILE}"
elif [[ ${MANAGER_OPERATOR} == "delete" ]];then
    ./manager -name "${DIR_NAME_DATE}" \
              -cloud-manager-addr "${CLOUD_MANAGER_ADDR}" \
              -label ${MANAGER_LABEL} \
              -cmd delete 
    manager_exit=$?
    if [ ${manager_exit} -ne 0 ];then
        echo "can not delete tidb cluster"
        exit -2
    fi

else
    echo "error params $*"
fi
