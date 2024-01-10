#!/bin/bash

######################################################################################
#
# Description:
# ------------
#       This script adds ULA addresses for all interfaces in order to enable easy
#       IPv6 firewall rule management when dynamic IPv6 prefixes are to be used.
#		As IPv6 ULAs may be reseted whenever network config  is changed in GUI,
#       this file should be executed regularly via cron (see 99-setup-cron.sh) to 
#		ensure that firewall is permanently activated.
#
######################################################################################

######################################################################################
#
# Configuration
#

# WAN-Interface to be checked
wan_if="eth8 eth9"

# IPv6 hosts used to test IPv6 connection
host1="facebook.de"
host2="google.de"
host3="apple.com"
host4="microsoft.com"

# ULA prefix to be used
ula_prefix="fd00:2:0:"

# interfaces listed in exclude will not be assigned any IPv6 ULAs
# Multiple interfaces are to be separated by spaces.
exclude="br0"

# set ULA on guest interfaces?
guest_ula=false

#
# No further changes should be necessary beyond this line.
#
######################################################################################


# set scriptname
me=sixinator


# if script runs directly after boot wait 10 seconds to ensure all is up and running.
sleep 10


while true
do

	# If IPv6 connection is available nothing to do 
	if ( ping -6 -c 1 $host1 || ping -6 -c 1 $host2 || 
		ping -6 -c 1 $host3 || ping -6 -c 1 $host4 ); then 
		logger "$me: IPv6 working as expected. Nothing to do."
		echo "$me: IPv6 working as expected. Nothing to do."
	else    
		logger "$me: IPv6 connection lost."
		echo "$me: IPv6 connection lost."
		for w in $wan_if; do
			if ip -6 addr show dev $w | grep inet6; then
				logger "$me: Resetting interface $w."
				ifconfig $w down; ifconfig $w up
			fi
		done
	fi


	#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	# ULAs for LAN interfaces
	#

	# Get list of relevant LAN interfaces and total number of interfaces
	lan_if=$(iptables --list-rules UBIOS_FORWARD_IN_USER | awk '/-j UBIOS_LAN_IN_USER/ { print $4 }')

	# Add ULAs to all LAN interfaces except the ones listed in $exclude
	for i in $lan_if; do
		case "$exclude " in
			*"$i "*)
				logger "$me: Excluding $i from ULA assignment as requested in config."
				;;

			*)
				ip -6 addr show dev $i | grep "$ula_prefix" &> /dev/null ||
					ip -6 addr add "${ula_prefix}${i:2}::1/64" dev $i
				;;
		esac
	done


	#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	# ULAs for guest interfaces
	#

	if [ $guest_ula == "true" ]; then
		# Get list of relevant guest interfaces and total number of interfaces
		guest_if=$(iptables --list-rules UBIOS_FORWARD_IN_USER | awk '/-j UBIOS_GUEST_IN_USER/ { print $4 }')

		# Add ULAs to all LAN interfaces except the ones listed in $exclude
		for i in $guest_if; do
			case "$exclude " in
				*"$i "*)
					logger "$me: Excluding $i from ULA assignment as requested in config."
					;;

				*)
					ip -6 addr show dev $i | grep "$ula_prefix" &> /dev/null ||
						ip -6 addr add "${ula_prefix}${i:2}::1/64" dev $i
					;;
			esac
		done
	fi


    # sleep for one minute and then re-evaluate because changed in the 
    # Network UI could delete IPv6-ULAs.
    sleep 60
done
