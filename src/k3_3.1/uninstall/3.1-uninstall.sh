#!/bin/sh
#
# $Id: 3.1-uninstall.sh 15011 2018-06-02 16:58:21Z NiLuJe $
#

# Pull libOTAUtils for logging & progress handling
[ -f ./libotautils ] && source ./libotautils


# Hack specific config (name and when to start/stop)
HACKNAME="linkjail"
SLEVEL="64"
KLEVEL="09"

otautils_update_progressbar

# Remove our custom key
logmsg "I" "uninstall" "" "removing custom pubkey"
rm -f /etc/uks/pubhackkey01.pem

otautils_update_progressbar

# Switch back to default keys
if grep -q "^fsp /etc/uks/pubprodkey01.pem" /proc/mounts ; then
    logmsg "I" "uninstall" "" "switching back to default keys"
    umount -l /etc/uks/pubprodkey01.pem
fi

otautils_update_progressbar

# Boot symlink
logmsg "I" "uninstall" "" "removing boot symlink"
[ -h /etc/rc5.d/S${SLEVEL}${HACKNAME} ] && rm -f /etc/rc5.d/S${SLEVEL}${HACKNAME}

otautils_update_progressbar

# Updater symlink
logmsg "I" "uninstall" "" "removing update symlink"
[ -h /etc/rc3.d/K${KLEVEL}${HACKNAME} ] && rm -f /etc/rc3.d/K${KLEVEL}${HACKNAME}

otautils_update_progressbar

# Remove our hack's init script
logmsg "I" "uninstall" "" "removing init script"
[ -f /etc/init.d/${HACKNAME} ] && rm -f /etc/init.d/${HACKNAME}

otautils_update_progressbar

# Remove custom directory in userstore?
logmsg "I" "uninstall" "" "removing custom directory (only if /mnt/us/${HACKNAME}/uninstall exists)"
if [ -d /mnt/us/${HACKNAME} -a -f /mnt/us/${HACKNAME}/uninstall ] ; then
    rm -rf /mnt/us/${HACKNAME}
    logmsg "I" "uninstall" "" "custom directory has been removed"
fi

otautils_update_progressbar

logmsg "I" "uninstall" "" "done"

otautils_update_progressbar

return 0
