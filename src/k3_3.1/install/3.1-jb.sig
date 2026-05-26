#!/bin/sh
#
# FW 3.0.x-3.1 jailbreak install script.
#
# $Id: 3.1-install.sh 10686 2014-07-01 00:15:39Z NiLuJe $
#
##


### NOTE: Inlined copy of libotautils r10677...
## Logging
# Pull some helper functions for logging
_FUNCTIONS=/etc/rc.d/functions
[ -f ${_FUNCTIONS} ] && source ${_FUNCTIONS}

# Make sure HACKNAME is set (NOTE: This should be overriden in the update script)
[ -z "${HACKNAME}" ] && HACKNAME="ota_script"

# Slightly tweaked version of msg() (from ${_FUNCTIONS}, where the constants are defined)
logmsg()
{
	local _NVPAIRS
	local _FREETEXT
	local _MSG_SLLVL
	local _MSG_SLNUM

	_MSG_LEVEL="${1}"
	_MSG_COMP="${2}"

	{ [ $# -ge 4 ] && _NVPAIRS="${3}" && shift ; }

	_FREETEXT="${3}"

	eval _MSG_SLLVL=\${MSG_SLLVL_$_MSG_LEVEL}
	eval _MSG_SLNUM=\${MSG_SLNUM_$_MSG_LEVEL}

	local _CURLVL

	{ [ -f ${MSG_CUR_LVL} ] && _CURLVL=$(cat ${MSG_CUR_LVL}) ; } || _CURLVL=1

	if [ ${_MSG_SLNUM} -ge ${_CURLVL} ] ; then
		/usr/bin/logger -p local4.${_MSG_SLLVL} -t "${HACKNAME}" "${_MSG_LEVEL} def:${_MSG_COMP}:${_NVPAIRS}:${_FREETEXT}"
	fi

	[ "${_MSG_LEVEL}" != "D" ] && echo "${HACKNAME}: ${_MSG_LEVEL} def:${_MSG_COMP}:${_NVPAIRS}:${_FREETEXT}"
}


## Progressbar
# Check if arg is an int
is_integer()
{
	# Cheap trick ;)
	[ "${1}" -eq "${1}" ] 2>/dev/null
	return $?
}

# The amount of steps needed to fill the progress bar
# I'm lazy, so just count the amount of calls in the script itself ;)
# NOTE: Yup, $0 still points to the original script that sourced us :).
[ -z ${STEPCOUNT} ] && STEPCOUNT="$(grep -c '^[[:blank:]]*otautils_update_progressbar$' ${0} 2>/dev/null)"
# Make sure it's sane...
is_integer "${STEPCOUNT}" || STEPCOUNT=1
# NOTE: If you need to for some strange reason, this can be overriden in the update script

# In case we need to catch failure early...
otautils_die()
{
	# FIXME: Invest in a custom eips message?

	# And it is called die, after all ;)
	sleep 5
	exit 1
}

# Fill up our progress bar, one step at a time
# Keep track of what we're doing...
_CUR_STEP=0
_CUR_PERCENTAGE=0
otautils_update_progressbar()
{
	# One more step...
	_CUR_STEP=$((_CUR_STEP + 1))
	# Bounds checking...
	if [ ${_CUR_STEP} -lt 0 ] ; then
		_CUR_STEP=0
	elif [ ${_CUR_STEP} -gt ${STEPCOUNT} ] ; then
		_CUR_STEP=${STEPCOUNT}
	fi

	# Make that a percentage
	local bar_percentage=$(( (${_CUR_STEP} * 100) / ${STEPCOUNT} ))
	# We can only *fill* the bar...
	if [ ${_CUR_PERCENTAGE} -lt ${bar_percentage} ] ; then
		_CUR_PERCENTAGE=${bar_percentage}
	fi

	# Make sure that percentage is sane...
	is_integer "${_CUR_PERCENTAGE}" || _CUR_PERCENTAGE=0
	# Bounds checking...
	if [ ${_CUR_PERCENTAGE} -gt 100 ] ; then
		_CUR_PERCENTAGE=100
	elif [ ${_CUR_PERCENTAGE} -lt 0 ] ; then
		_CUR_PERCENTAGE=0
	fi

	# Finally, refresh the bar (otautils_update_progressbaris from ${_FUNCTIONS)
	otautils_update_progressbar${_CUR_PERCENTAGE}
	if [ $? -eq 0 ] ; then
		logmsg "D" "guiprogress" "progress=${_CUR_PERCENTAGE}" "update progress indicator"
	else
		logmsg "W" "guiprogress" "progress=${_CUR_PERCENTAGE},status=fail" "update progress indicator"
	fi
}
###


# Hack specific config (name and when to start/stop)
HACKNAME="linkjail"
SLEVEL="64"
KLEVEL="09"

# We're gonna need this for our eips calls...
EIPS_MAXLINES="$((${SCREEN_Y_RES} / ${EIPS_Y_RES}))"

otautils_update_progressbar

# Check if another jailbreak isn't already installed
if [ -f /etc/init.d/jailbreak -a -h /etc/rc5.d/S64jailbreak -a -h /etc/rc3.d/K09jailbreak -a -f /etc/uks/pubprodkey01.hack.pem ] ; then
    # yifanlu's jailbreak seems to be fully installed, abort, log it, and then try to warn the user in a visible way, without having to go digging in the logs.
    logmsg "E" "install" "" "Another jailbreak is already installed, aborting."

    # Print a visible message, in place of the error code, for 10s
    for jb_countdown in $(seq 1 10) ; do
        eips 0 $((${EIPS_MAXLINES} - 2)) " Found another jailbreak, aborting${jb_spinner}"
        jb_spinner="${jb_spinner}."
        sleep 1
    done

    return 1
fi

otautils_update_progressbar

# Check that our public keys aren't in an inconsistent state (ie. after a borked jailbreak uninstall, or before a full restart just after an uninstall of some jailbreak versions)
# NOTE/FIXME/IMDUMB: This is pretty much unreachable with jailbreaks targeting FW >= 3.1, otaup would already have died with a U007 error *before* we even got a chance to run.
pk_unexpected_md5="7130ce39bb3596c5067cabb377c7a9ed"
pk_current_md5="$( md5sum /etc/uks/pubprodkey01.pem )"
if [ "${pk_current_md5}" == "${pk_unexpected_md5}" ] ; then
    # We found our custom hack key, when we should have found the original pubkey, abort, log, and warn the user.
    logmsg "E" "install" "" "Inconsistent pubkey state (found: hack, expected: original), aborting."

    # We're gonna need some space...
    eips 0 $((${EIPS_MAXLINES} - 5)) " Found traces of another jailbreak..."
    eips 0 $((${EIPS_MAXLINES} - 4)) " Make sure one is not already installed, then"
    eips 0 $((${EIPS_MAXLINES} - 3)) " try again after a full restart of your Kindle."
    # Print a visible message, in place of the error code, for 10s
    for jb_countdown in $(seq 1 10) ; do
        eips 0 $((${EIPS_MAXLINES} - 2)) " Aborting${jb_spinner}"
        jb_spinner="${jb_spinner}."
        sleep 1
    done

    return 1
fi

otautils_update_progressbar

# Install our key (In case we're still on FW 3.0.x)
logmsg "I" "install" "" "installing our custom public key"
cat <<EOF > /etc/uks/pubhackkey01.pem
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDJn1jWU+xxVv/eRKfCPR9e47lP
WN2rH33z9QbfnqmCxBRLP6mMjGy6APyycQXg3nPi5fcb75alZo+Oh012HpMe9Lnp
eEgloIdm1E4LOsyrz4kttQtGRlzCErmBGt6+cAVEV86y2phOJ3mLk0Ek9UQXbIUf
rvyJnS2MKLG2cczjlQIDAQAB
-----END PUBLIC KEY-----
EOF

otautils_update_progressbar

# Install our hack's custom content
# But keep the user's custom content...
if [ -d /mnt/us/${HACKNAME} ] ; then
    logmsg "I" "install" "" "our custom directory already exists, checking if we have custom content to preserve"
    # Hacks whitelist
    wl_expected_md5="ac86b6c64dab7e3f7bfdabad970afd57 21fdce627766d21e6b858ad550c861fa 60296efa9a39f184dded04c3433f8447 e7f079fad085a38d1c649cb4f94376ee a53a46af6eaedd72eff8b6bedfb095da de2ce68ad1812c7ea28117517f40952e 3d79664c8d4c6550aeda9e62b34fd039 507b1c8af223ec03e29a4915a074d86c d601fbdaaf5f83647e6ce66b63dbf916 b8e1cb5c9fa1fc209f9f041c797aeb7c b76db0b6c1a137b116fb95034f33125b 81620f70e8c7ca531c1841c7360908ba 56c0dd27149dbb544fdcae7d5aef6010 5f664336774e85352074c7e7a1c25a30 11140f7cc69f72633413cb56629e364a cbfcc2c7af55dfb53981e2a3d9e5d3bd 69e6c18048ae3141adea594303113931"
    # And perform the actual check
    wl_md5_match="false"
    # Check if it exists at all...
    if [ -f /mnt/us/${HACKNAME}/etc/whitelist ] ; then
        wl_current_md5=$( md5sum /mnt/us/${HACKNAME}/etc/whitelist | awk '{ print $1; }' )
        for cur_exp_md5 in ${wl_expected_md5} ; do
            if [ "${wl_current_md5}" == "${cur_exp_md5}" ] ; then
                wl_md5_match="true"
            fi
        done
        if [ "${wl_md5_match}" != "true" ] ; then
            HACK_EXCLUDE="/mnt/us/${HACKNAME}/etc/whitelist"
            logmsg "I" "install" "" "found custom whitelist, excluding from archive"
        fi
    else
        logmsg "I" "install" "" "custom whitelist missing, it'll be installed"
    fi
fi

otautils_update_progressbar

# Okay, now we can extract it. Since busybox's tar is very limited, we have to use a tmp directory to perform our filtering
logmsg "I" "install" "" "installing custom directory"
tar -xvzf ${HACKNAME}.tgz.sig
# Do check if that went well
_RET=$?
if [ ${_RET} -ne 0 ] ; then
    logmsg "C" "install" "code=${_RET}" "failed to extract custom directory in tmp location"
    return 1
fi

# That's very much inspired from official update scripts ;)
cd src
# And now we filter the content to preserve user's custom content
for custom_file in ${HACK_EXCLUDE} ; do
    if [ -f "./${custom_file}" ] ; then
        logmsg "I" "install" "" "preserving custom content (${custom_file})"
        rm -f "./${custom_file}"
    fi
done
# Finally, re-tape our filtered dir and unleash it on the live userstore
tar cf - . | (cd /mnt/us ; tar xvf -)
_RET=$?
if [ ${_RET} -ne 0 ] ; then
    logmsg "C" "install" "code=${_RET}" "failure to update userstore with custom directory"
    return 1
fi
cd - >/dev/null
rm -rf src

otautils_update_progressbar

# Install our hack's init script
logmsg "I" "install" "" "installing init script"
cp -f ${HACKNAME}-init.sig /etc/init.d/${HACKNAME}

otautils_update_progressbar

# Make it executable
logmsg "I" "install" "" "chmoding init script"
[ -x /etc/init.d/${HACKNAME} ] || chmod +x /etc/init.d/${HACKNAME}

otautils_update_progressbar

# Make it start (stop, actually) at boot (rc5), after dbus and before pmond and the framework
logmsg "I" "install" "" "creating boot runlevel symlink"
[ -h /etc/rc5.d/S${SLEVEL}${HACKNAME} ] || ln -fs /etc/init.d/${HACKNAME} /etc/rc5.d/S${SLEVEL}${HACKNAME}

otautils_update_progressbar

# Make it stop (start, actually) when updating (rc3), after the framework and before the updater
logmsg "I" "install" "" "creating update runlevel symlink"
[ -h /etc/rc3.d/K${KLEVEL}${HACKNAME} ] || ln -fs /etc/init.d/${HACKNAME} /etc/rc3.d/K${KLEVEL}${HACKNAME}

otautils_update_progressbar

# Cleanup
logmsg "I" "install" "" "cleaning up"
rm -f ${HACKNAME}-init.sig ${HACKNAME}.tgz.sig

otautils_update_progressbar

logmsg "I" "install" "" "done"

otautils_update_progressbar

return 0
