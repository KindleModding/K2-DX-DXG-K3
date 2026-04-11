#!/bin/sh
#
# Nifty FW 3.0.x jailbreak install script. (Works on 3.0.3)
#
# $Id: 3.0-install.sh 10686 2014-07-01 00:15:39Z NiLuJe $
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
###


HACKNAME="jailbreak"

# Install our key
logmsg "I" "jailbreak" "" "installing our custom public key"
cat <<EOF > /etc/uks/pubhackkey01.pem
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDJn1jWU+xxVv/eRKfCPR9e47lP
WN2rH33z9QbfnqmCxBRLP6mMjGy6APyycQXg3nPi5fcb75alZo+Oh012HpMe9Lnp
eEgloIdm1E4LOsyrz4kttQtGRlzCErmBGt6+cAVEV86y2phOJ3mLk0Ek9UQXbIUf
rvyJnS2MKLG2cczjlQIDAQAB
-----END PUBLIC KEY-----
EOF

return 0
