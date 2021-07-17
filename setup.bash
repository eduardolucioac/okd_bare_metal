#!/bin/bash

# > -------------------
# SETUP PARAMETERS

# The domain for the OpenShift (OKD) cluster.
# IMPORTANT: The domain used to install the cluster CANNOT BE CHANGED! See documentation!
# By Questor
OKD_DOMAIN="okd.local"

# First 3 octets of OpenShift (OKD) cluster network (forward and reverse).
OKD_LAN_24="10.3.0"
OKD_LAN_24_REVERSE="0.3.10"

# Last octet of the OKD_SERVICES server IP and its MAC address.
OKD_SERVICES_LST_OCT="3"

# Last octet of the OKD_BOOTSTRAP node IP and its MAC address.
OKD_BOOTSTRAP_LST_OCT="19"
OKD_BOOTSTRAP_MAC="52:54:00:07:80:62"

# Last octet of the OKD_MASTER_1 node IP and its MAC address.
OKD_MASTER_1_LST_OCT="4"
OKD_MASTER_1_MAC="52:54:00:7d:97:70"

# Last octet of the OKD_MASTER_2 node IP and its MAC address.
OKD_MASTER_2_LST_OCT="5"
OKD_MASTER_2_MAC="52:54:00:6e:52:85"

# Last octet of the OKD_MASTER_3 node IP and its MAC address.
OKD_MASTER_3_LST_OCT="6"
OKD_MASTER_3_MAC="52:54:00:a3:65:d9"

# Last octet of the OKD_WORKER_1 node IP and its MAC address.
OKD_WORKER_1_LST_OCT="12"
OKD_WORKER_1_MAC="52:54:00:e3:7c:fb"

# Last octet of the OKD_WORKER_2 node IP and its MAC address.
OKD_WORKER_2_LST_OCT="13"
OKD_WORKER_2_MAC="52:54:00:20:ec:4f"

# NOTES:
# I - In case you want to add new master or worker nodes, in the examples above I
# left a gap for 5 sequential IPs for new master nodes (last octets 7, 8, 9, 10 and
# 11) and a gap for 5 sequential IPs for new worker nodes (last octets 14, 15, 16,
# 17 and 18);
# II - All network settings refer to OpenShift (OKD) cluster network ([N]OKD_LAN).
# By Questor

# Available disk space (in GB) for OKD_SERVICES server minus 15. E.g.: 60-15=45.
OKD_SERVICES_STRG_SZ="45"

# < -------------------

# > -------------------
# UTILITY RESOURCES

F_EZ_SED_ECP_R=""
f_power_sed_ecp() {
    : 'Escape strings for the "sed" command.

    Args:
        F_VAL_TO_ECP (str): Value to be escaped.
        F_ECP_TYPE (int): 0 - For the TARGET value; 1 - For the REPLACE value.

    Returns:
        F_EZ_SED_ECP_R (str): Escaped value.
    '

    F_VAL_TO_ECP=$1
    F_ECP_TYPE=$2
    if [ ${F_ECP_TYPE} -eq 0 ] ; then
    # NOTE: For the TARGET value. By Questor

        F_EZ_SED_ECP_R=$(echo "x${F_VAL_TO_ECP}x" | sed 's/[]\/$*.^|[]/\\&/g' | sed 's/\t/\\t/g' | sed "s/'/\\\x27/g")
    else
    # NOTE: For the REPLACE value. By Questor

        F_EZ_SED_ECP_R=$(echo "x${F_VAL_TO_ECP}x" | sed 's/[]\/$*.^|[]/\\&/g' | sed 's/\t/\\t/g' | sed "s/'/\\\x27/g" | sed ':a;N;$!ba;s/\n/\\n/g')
    fi

    F_EZ_SED_ECP_R=${F_EZ_SED_ECP_R%?}
    F_EZ_SED_ECP_R=${F_EZ_SED_ECP_R#?}

}

F_EZ_SED_R=""
f_ez_sed() {
    : 'Facilitate the use of the "sed" command. Replaces in files and strings.

    Args:
        F_TARGET (str): Value to be replaced by the value of F_REPLACE.
        F_REPLACE (str): Value that will replace F_TARGET.
        F_FILE (Optional[str]): File in which the replacement will be made.
        F_ALL_OCCUR (Optional[int]): 0 - Replace only on the first occurrence; 
1 - Replace every occurrence. Default 0.
    '

    F_TARGET=$1
    F_REPLACE=$2
    F_FILE=$3
    F_ALL_OCCUR=$4
    if [ -z "$F_ALL_OCCUR" ] ; then
        F_ALL_OCCUR=0
    fi
    f_power_sed_ecp "$F_TARGET" 0
    F_TARGET=$F_EZ_SED_ECP_R
    f_power_sed_ecp "$F_REPLACE" 1
    F_REPLACE=$F_EZ_SED_ECP_R
    if [ ${F_ALL_OCCUR} -eq 0 ] ; then
        SED_RPL="'0,/$F_TARGET/s//$F_REPLACE/g'"
    else
        SED_RPL="'s/$F_TARGET/$F_REPLACE/g'"
    fi

    eval "sed -i $SED_RPL $F_FILE"

}

# NOTE: Get the folder path from "setup.bash" file and change the working directory
# to that path to avoid problems with relative paths. By Questor
SCRIPTDIR_V="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPTDIR_V"

# < -------------------

# > -------------------
# OpenShift (OKD) - Configuration/bootstrap files

# File ./install-config.yaml
f_ez_sed "<OKD_DOMAIN>" "$OKD_DOMAIN" "$SCRIPTDIR_V/install-config.yaml" 1

# File ./registry_pv.yaml
f_ez_sed "<OKD_LAN_24>" "$OKD_LAN_24" "$SCRIPTDIR_V/registry_pv.yaml" 1
f_ez_sed "<OKD_SERVICES_LST_OCT>" "$OKD_SERVICES_LST_OCT" "$SCRIPTDIR_V/registry_pv.yaml" 1
f_ez_sed "<OKD_SERVICES_STRG_SZ>" "$OKD_SERVICES_STRG_SZ" "$SCRIPTDIR_V/registry_pv.yaml" 1

# File ./registry_pvc.yaml
f_ez_sed "<OKD_SERVICES_STRG_SZ>" "$OKD_SERVICES_STRG_SZ" "$SCRIPTDIR_V/registry_pvc.yaml" 1

# < -------------------

# > -------------------
# ISC DHCP server - DHCP service

# File ./dhcpd.conf
f_ez_sed "<OKD_BOOTSTRAP_LST_OCT>" "$OKD_BOOTSTRAP_LST_OCT" "$SCRIPTDIR_V/dhcpd.conf" 1
f_ez_sed "<OKD_BOOTSTRAP_MAC>" "$OKD_BOOTSTRAP_MAC" "$SCRIPTDIR_V/dhcpd.conf" 1
f_ez_sed "<OKD_DOMAIN>" "$OKD_DOMAIN" "$SCRIPTDIR_V/dhcpd.conf" 1
f_ez_sed "<OKD_LAN_24>" "$OKD_LAN_24" "$SCRIPTDIR_V/dhcpd.conf" 1
f_ez_sed "<OKD_MASTER_1_LST_OCT>" "$OKD_MASTER_1_LST_OCT" "$SCRIPTDIR_V/dhcpd.conf" 1
f_ez_sed "<OKD_MASTER_1_MAC>" "$OKD_MASTER_1_MAC" "$SCRIPTDIR_V/dhcpd.conf" 1
f_ez_sed "<OKD_MASTER_2_LST_OCT>" "$OKD_MASTER_2_LST_OCT" "$SCRIPTDIR_V/dhcpd.conf" 1
f_ez_sed "<OKD_MASTER_2_MAC>" "$OKD_MASTER_2_MAC" "$SCRIPTDIR_V/dhcpd.conf" 1
f_ez_sed "<OKD_MASTER_3_LST_OCT>" "$OKD_MASTER_3_LST_OCT" "$SCRIPTDIR_V/dhcpd.conf" 1
f_ez_sed "<OKD_MASTER_3_MAC>" "$OKD_MASTER_3_MAC" "$SCRIPTDIR_V/dhcpd.conf" 1
f_ez_sed "<OKD_SERVICES_LST_OCT>" "$OKD_SERVICES_LST_OCT" "$SCRIPTDIR_V/dhcpd.conf" 1
f_ez_sed "<OKD_WORKER_1_LST_OCT>" "$OKD_WORKER_1_LST_OCT" "$SCRIPTDIR_V/dhcpd.conf" 1
f_ez_sed "<OKD_WORKER_1_MAC>" "$OKD_WORKER_1_MAC" "$SCRIPTDIR_V/dhcpd.conf" 1
f_ez_sed "<OKD_WORKER_2_LST_OCT>" "$OKD_WORKER_2_LST_OCT" "$SCRIPTDIR_V/dhcpd.conf" 1
f_ez_sed "<OKD_WORKER_2_MAC>" "$OKD_WORKER_2_MAC" "$SCRIPTDIR_V/dhcpd.conf" 1

# < -------------------

# > -------------------
# ISC BIND 9 - DNS service

# File ./named.conf
f_ez_sed "<OKD_LAN_24>" "$OKD_LAN_24" "$SCRIPTDIR_V/named.conf" 1
f_ez_sed "<OKD_SERVICES_LST_OCT>" "$OKD_SERVICES_LST_OCT" "$SCRIPTDIR_V/named.conf" 1

# File ./named.conf.local
f_ez_sed "<OKD_DOMAIN>" "$OKD_DOMAIN" "$SCRIPTDIR_V/named.conf.local" 1
f_ez_sed "<OKD_LAN_24_REVERSE>" "$OKD_LAN_24_REVERSE" "$SCRIPTDIR_V/named.conf.local" 1

# File ./fw.okd_domain
f_ez_sed "<OKD_BOOTSTRAP_LST_OCT>" "$OKD_BOOTSTRAP_LST_OCT" "$SCRIPTDIR_V/fw.okd_domain" 1
f_ez_sed "<OKD_DOMAIN>" "$OKD_DOMAIN" "$SCRIPTDIR_V/fw.okd_domain" 1
f_ez_sed "<OKD_LAN_24>" "$OKD_LAN_24" "$SCRIPTDIR_V/fw.okd_domain" 1
f_ez_sed "<OKD_MASTER_1_LST_OCT>" "$OKD_MASTER_1_LST_OCT" "$SCRIPTDIR_V/fw.okd_domain" 1
f_ez_sed "<OKD_MASTER_2_LST_OCT>" "$OKD_MASTER_2_LST_OCT" "$SCRIPTDIR_V/fw.okd_domain" 1
f_ez_sed "<OKD_MASTER_3_LST_OCT>" "$OKD_MASTER_3_LST_OCT" "$SCRIPTDIR_V/fw.okd_domain" 1
f_ez_sed "<OKD_SERVICES_LST_OCT>" "$OKD_SERVICES_LST_OCT" "$SCRIPTDIR_V/fw.okd_domain" 1
f_ez_sed "<OKD_WORKER_1_LST_OCT>" "$OKD_WORKER_1_LST_OCT" "$SCRIPTDIR_V/fw.okd_domain" 1
f_ez_sed "<OKD_WORKER_2_LST_OCT>" "$OKD_WORKER_2_LST_OCT" "$SCRIPTDIR_V/fw.okd_domain" 1

# File ./rv.okd_domain
f_ez_sed "<OKD_BOOTSTRAP_LST_OCT>" "$OKD_BOOTSTRAP_LST_OCT" "$SCRIPTDIR_V/rv.okd_domain" 1
f_ez_sed "<OKD_DOMAIN>" "$OKD_DOMAIN" "$SCRIPTDIR_V/rv.okd_domain" 1
f_ez_sed "<OKD_MASTER_1_LST_OCT>" "$OKD_MASTER_1_LST_OCT" "$SCRIPTDIR_V/rv.okd_domain" 1
f_ez_sed "<OKD_MASTER_2_LST_OCT>" "$OKD_MASTER_2_LST_OCT" "$SCRIPTDIR_V/rv.okd_domain" 1
f_ez_sed "<OKD_MASTER_3_LST_OCT>" "$OKD_MASTER_3_LST_OCT" "$SCRIPTDIR_V/rv.okd_domain" 1
f_ez_sed "<OKD_SERVICES_LST_OCT>" "$OKD_SERVICES_LST_OCT" "$SCRIPTDIR_V/rv.okd_domain" 1
f_ez_sed "<OKD_WORKER_1_LST_OCT>" "$OKD_WORKER_1_LST_OCT" "$SCRIPTDIR_V/rv.okd_domain" 1
f_ez_sed "<OKD_WORKER_2_LST_OCT>" "$OKD_WORKER_2_LST_OCT" "$SCRIPTDIR_V/rv.okd_domain" 1

# < -------------------

# > -------------------
# HAProxy - load balancer service

# File ./haproxy.cfg
f_ez_sed "<OKD_BOOTSTRAP_LST_OCT>" "$OKD_BOOTSTRAP_LST_OCT" "$SCRIPTDIR_V/haproxy.cfg" 1
f_ez_sed "<OKD_LAN_24>" "$OKD_LAN_24" "$SCRIPTDIR_V/haproxy.cfg" 1
f_ez_sed "<OKD_MASTER_1_LST_OCT>" "$OKD_MASTER_1_LST_OCT" "$SCRIPTDIR_V/haproxy.cfg" 1
f_ez_sed "<OKD_MASTER_2_LST_OCT>" "$OKD_MASTER_2_LST_OCT" "$SCRIPTDIR_V/haproxy.cfg" 1
f_ez_sed "<OKD_MASTER_3_LST_OCT>" "$OKD_MASTER_3_LST_OCT" "$SCRIPTDIR_V/haproxy.cfg" 1
f_ez_sed "<OKD_WORKER_1_LST_OCT>" "$OKD_WORKER_1_LST_OCT" "$SCRIPTDIR_V/haproxy.cfg" 1
f_ez_sed "<OKD_WORKER_2_LST_OCT>" "$OKD_WORKER_2_LST_OCT" "$SCRIPTDIR_V/haproxy.cfg" 1

# < -------------------

exit 0
