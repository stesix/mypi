#!/bin/bash

runtime_path=$( dirname $0 )

ipcheck_url='ipecho.net/plain'
ifconfig_cmd='sudo /sbin/ifconfig'

network_iface='tun0'
ip_file="${runtime_path}/ip.txt"

setting_json='/etc/transmission-daemon/settings.json'

transmission='transmission-daemon'

function check_ip {
	$ifconfig_cmd ${network_iface} &> /dev/null
	local exit_status=$?
	if [ $exit_status -ne 0 ] ; then
		change_ip_in_transmission "127.0.0.1"
		echo "VPN not running"
		exit 1
	fi

	local tun_iface="$( ${ifconfig_cmd} ${network_iface} | grep "inet addr" | cut -d: -f2 | cut -d' ' -f1 )"
	local exit_status=$?

	if [ $exit_status -ne 0 ] ; then
		change_ip_in_transmission "127.0.0.1"
		echo "VPN not running"
		exit 1
	fi

	local old_ip="$( sudo cat $setting_json | grep "bind-address-ipv4" | cut -d: -f2 | cut -d'"' -f2 )"

	if [ "$tun_iface" != "${old_ip}" ] ; then
		public_ip="$( curl ${ipcheck_url} 2> /dev/null )"
		echo "${public_ip}" > ${ip_file}
		echo "IP change."
		change_ip_in_transmission "${tun_iface}"
	fi
}

function change_ip_in_transmission {
	local ifconfig_remote=$1

	sudo service ${transmission} stop
	sudo sed -i 's/.*"bind-address-ipv4":.*/    "bind-address-ipv4": "'$ifconfig_remote'",/' $setting_json
	sudo service ${transmission} start
}


check_ip

