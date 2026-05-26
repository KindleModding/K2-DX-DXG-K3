#!/bin/sh
#
# $Id: uninstall.sh 10686 2014-07-01 00:15:39Z NiLuJe $
#


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


HACKNAME="jailbreak"

otautils_update_progressbar

# Remove our custom key
logmsg "I" "uninstall" "" "removing custom pubkey"
rm -f /etc/uks/pubhackkey01.pem

otautils_update_progressbar

return 0
