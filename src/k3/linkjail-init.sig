#!/bin/sh
#
# $Id: linkjail-init 7305 2011-02-27 16:23:19Z NiLuJe $
#

_FUNCTIONS=/etc/rc.d/functions
[ -f ${_FUNCTIONS} ] && . ${_FUNCTIONS}

LINKJAIL_EMERGENCY="/mnt/us/linkjail/bin/emergency.sh"
LINKJAIL_SCRIPT="/mnt/us/linkjail/bin/unlinkjail"
LINKJAIL_SCRIPT_STOP="/mnt/us/linkjail/bin/linkjail"

case "$1" in
        start)
                # First things first, check for an emergency script
                if [ -f ${LINKJAIL_EMERGENCY} ] ; then
                        # We got one, make it executable and use it
                        [ -x ${LINKJAIL_EMERGENCY} ] || chmod +x ${LINKJAIL_EMERGENCY}
                        # Run it...
                        msg "running unlinkjail emergency script" I
                        ${LINKJAIL_EMERGENCY}
                        # And GET OUT! NOW!
                        exit 0
                fi
                # Everything's fine, yeepee.
                if [ -f ${LINKJAIL_SCRIPT} ] ; then
                        # We got our script, make it executable
                        [ -x ${LINKJAIL_SCRIPT} ] || chmod +x ${LINKJAIL_SCRIPT}
                        # And run it!
                        msg "running unlinkjail" I
                        ${LINKJAIL_SCRIPT}
                else
                        msg "couldn't run unlinkjail" W
                fi
        ;;
        stop)
                if [ -f ${LINKJAIL_SCRIPT_STOP} ] ; then
                        # We got our script, make it executable
                        [ -x ${LINKJAIL_SCRIPT_STOP} ] || chmod +x ${LINKJAIL_SCRIPT_STOP}
                        # And run it!
                        msg "running linkjail" I
                        ${LINKJAIL_SCRIPT_STOP}
                else
                        msg "couldn't run linkjail" W
                fi
        ;;
        *)
                msg "Usage: $0 {start|stop}" W >&2
                exit 1
        ;;
esac

exit 0
