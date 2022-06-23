. /lib/functions.sh

load_wifi() {
	local kernel_version=$(uname -r)
	[ -e "/lib/modules/$kernel_version/mt_wifi.ko" ] && modprobe mt_wifi
	[ -e "/lib/modules/$kernel_version/mt_whnat.ko" ] && modprobe mt_whnat
}

boot_hook_add preinit_main load_wifi
