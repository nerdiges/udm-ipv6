#!/bin/bash

######################################################################################
#
# Description:
# ------------
#	This script adds ULA addresses for selected interfaces in order to enable easy
#	IPv6 firewall rule management when dynamic IPv6 prefixes are to be used.
#	As IPv6 ULAs may be reseted whenever network config  is changed in GUI,
#	this file should be executed regularly via systemd timer to ensure that  
#	firewall is permanently activated.
#
######################################################################################

######################################################################################
#
# Configuration
#

# check and try to restore IPv6 connection
check_v6=true

# IPv6 hosts used to test IPv6 connection
host1="facebook.de"
host2="google.de"
host3="apple.com"
host4="microsoft.com"

# list of WAN interfaces 
# default for UDM Pro: 
#	eht9 = primary WAN interface
#	eht8 = secondary WAN interface
wan_if="eth9 eth8"

# List with ULAs that should be assigned to local interfaces
# Each entry of the array must contain the interface name
# followed by the ULA prefix that should be assigned.
# Interface name and ULA prefix should be separated by a space.
ula_list=(
	"br0 fd00:2:0:0"
	"br5 fd00:2:0:5"
)

#
# No further changes should be necessary beyond this line.
#
######################################################################################

# set scriptname
me=$(basename $0)

# include local configuration if available
[ -e "$(dirname $0)/${me%.*}.conf" ] && source "$(dirname $0)/${me%.*}.conf"


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# check ipv6 connection
#
if [ $check_v6 == "true" ]; then
	# If IPv6 connection is available nothing to do 
	if ( ping -6 -c 1 $host1 || ping -6 -c 1 $host2 || 
		ping -6 -c 1 $host3 || ping -6 -c 1 $host4 ); then 
		logger -s "$me: INFO: IPv6 working as expected. Nothing to do."
	else    
		logger -s "$me: WARNING: IPv6 connection lost."
		for w in $wan_if; do
			if ip -6 addr show dev $w | grep inet6; then
				logger -s "$me: INFO: Resetting interface $w."
				ifconfig $w down; ifconfig $w up
			fi
		done
	fi
fi


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# add ULAs for configured interfaces
#
for i in "${ula_list[@]}"; do
	dev=${i% *}
	ula_prefix=${i#* }
	echo $dev - $ula_prefix
	if ! ip -6 addr show dev $dev | grep "$ula_prefix" &> /dev/null; then
		ip -6 addr add "${ula_prefix}::1/64" dev $dev &&
			logger -s "$me: INFO: ULA ${ula_prefix}::1/64 added to $dev." ||
			logger -s "$me: WARNING: ULA ${ula_prefix}::1/64 could not be added to $dev." 
	fi
done
