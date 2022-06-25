#!/bin/sh
#
# Copyright (c) 2014 OpenWrt
# Copyright (C) 2013-2015 D-Team Technology Co.,Ltd. ShenZhen
# Copyright (c) 2005-2015, lintel <lintel.huang@gmail.com>
# Copyright (c) 2013, Hoowa <hoowa.sun@gmail.com>
# Copyright (c) 2015-2017, GuoGuo <gch981213@gmail.com>
# Copyright (c) 2021-2022, Nanchuci <nanchuci023gmail.com>
#
# 	Detect script for MT7615 DBDC mode
#
# 	嘿，对着屏幕的哥们,为了表示对原作者辛苦工作的尊重，任何引用跟借用都不允许你抹去所有作者的信息,请保留这段话。
#

append DRIVERS "mt_dbdc"

. /lib/functions.sh
. /lib/functions/system.sh

mt_get_first_if_mac() {
	local wlan_mac=""
	factory_part=$(find_mtd_part factory)
	[ -z "$factory_part" ] && factory_part=$(find_mtd_part Factory)
	dd bs=1 skip=4 count=6 if=$factory_part 2>/dev/null | /usr/sbin/maccalc bin2mac	
}

detect_mt_dbdc() {
	local macaddr
	[ -d /sys/module/mt_wifi ] && [ $( grep -c ra0 /proc/net/dev) -eq 1 ] && {
		for phyname in ra0 rax0; do
			config_get type $phyname type
			macaddr=$(mt_get_first_if_mac)
			[ "$type" == "mt_dbdc" ] || {
				case $phyname in
					ra0)
						band=2g
						htmode=HT20
						pb_smart=1
						noscan=0
						ssid="OpenWRT-2.4G-$(echo $macaddr | awk -F ":" '{print $4""$5""$6 }'| tr a-z A-Z)"
						;;
					rax0)
						band=5g
						htmode=VHT80
						ssid="OpenWRT-5G-$(maccalc add $macaddr 3145728 | awk -F ":" '{print $4""$5""$6 }'| tr a-z A-Z)"
						pb_smart=0
						noscan=1
						;;
				esac
				
				if [ -n "$macaddr" ]; then
					dev_id="set wireless.${phyname}.macaddr=${macaddr}"
				else
					dev_id="set wireless.${phyname}.macaddr=$(cat /sys/class/ieee80211/${dev}/macaddress)"
				fi
				}

				get_band_defaults() {
					local phy="$1"

					for c in $(__get_band_defaults "$phy"); do
						local band="${c%%:*}"
						c="${c#*:}"
						local chan="${c%%:*}"
						c="${c#*:}"
						local mode="${c%%:*}"

						case "$band" in
							1) band=2g;;
							2) band=5g;;
							3) band=60g;;
							4) band=6g;;
							*) band="";;
						esac

						[ -n "$band" ] || continue
						[ -n "$mode_band" -a "$band" = "6g" ] && return

						mode_band="$band"
						channel="$chan"
						htmode="$mode"
					done
				}

				uci -q batch <<-EOF
					set wireless.${phyname}=wifi-device
					set wireless.${phyname}.type=mt_dbdc
					set wireless.${phyname}.band=${mode_band}
					set wireless.${phyname}.channel=auto
					set wireless.${phyname}.txpower=100
					set wireless.${phyname}.htmode=$htmode
					set wireless.${phyname}.country=US
					set wireless.${phyname}.txburst=1
					set wireless.${phyname}.noscan=$noscan
					set wireless.${phyname}.smart=$pb_smart

					set wireless.default_${phyname}=wifi-iface
					set wireless.default_${phyname}.device=${phyname}
					set wireless.default_${phyname}.network=lan
					set wireless.default_${phyname}.mode=ap
					set wireless.default_${phyname}.ssid=${ssid}
					set wireless.default_${phyname}.encryption=none
				EOF
				uci -q commit wireless
			}
		done
	}
}
