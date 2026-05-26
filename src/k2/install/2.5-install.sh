#!/bin/sh

# diff OTA patch script 

_FUNCTIONS=/etc/rc.d/functions
[ -f ${_FUNCTIONS} ] && . ${_FUNCTIONS}


MSG_SLLVL_D="debug"
MSG_SLLVL_I="info"
MSG_SLLVL_W="warn"
MSG_SLLVL_E="err"
MSG_SLLVL_C="crit"
MSG_SLNUM_D=0
MSG_SLNUM_I=1
MSG_SLNUM_W=2
MSG_SLNUM_E=3
MSG_SLNUM_C=4
MSG_CUR_LVL=/var/local/system/syslog_level

logmsg()
{
    local _NVPAIRS
    local _FREETEXT
    local _MSG_SLLVL
    local _MSG_SLNUM

    _MSG_LEVEL=$1
    _MSG_COMP=$2

    { [ $# -ge 4 ] && _NVPAIRS=$3 && shift ; }

    _FREETEXT=$3

    eval _MSG_SLLVL=\${MSG_SLLVL_$_MSG_LEVEL}
    eval _MSG_SLNUM=\${MSG_SLNUM_$_MSG_LEVEL}

    local _CURLVL

    { [ -f $MSG_CUR_LVL ] && _CURLVL=`cat $MSG_CUR_LVL` ; } || _CURLVL=1

    if [ $_MSG_SLNUM -ge $_CURLVL ]; then
        /usr/bin/logger -p local4.$_MSG_SLLVL -t "ota_install" "$_MSG_LEVEL def:$_MSG_COMP:$_NVPAIRS:$_FREETEXT"
    fi

    [ "$_MSG_LEVEL" != "D" ] && echo "ota_install: $_MSG_LEVEL def:$_MSG_COMP:$_NVPAIRS:$_FREETEXT"
}

if [ -z "${_COMPLETE_COUNT}" ]; then
    export _COMPLETE_COUNT=0
fi

_CUR_PERCENT_COMPLETE=-1

update_percent_complete()
{
    _COMPLETE_COUNT=$((${_COMPLETE_COUNT} + $1))

    local _PROGRESS_PERCENT=$(($((${_COMPLETE_COUNT} * 100)) / 17))

    if [ ${_CUR_PERCENT_COMPLETE} -ne ${_PROGRESS_PERCENT} ]; then
        update_progressbar ${_PROGRESS_PERCENT}

        _CUR_PERCENT_COMPLETE=${_PROGRESS_PERCENT}
    fi
}

update_percent_complete_unscaled()
{
	update_percent_complete $(($1 * 0))
}

update_percent_complete_unscaled 1

perform_patches()
{
  logmsg "I" "patch" "patchinfo=\"/etc/prettyversion.txt\"" "patching file"

  mkdir -p patch/etc/
  bspatch /etc/prettyversion.txt patch/etc/prettyversion.txt 000.prettyversion.txt.patch
  if [ $? -ne 0 ]; then
    logmsg "C" "patch" "patchinfo=\"/etc/prettyversion.txt\"" "patch failure"
    return 1
  fi

  _PATCH_MD5=`md5sum patch/etc/prettyversion.txt | awk '{ print $1; }'`
  _EXPECTED_MD5=6d966b7eea464a05e4b2a9af2b456ffc
  if [ ! "${_PATCH_MD5}" = "${_EXPECTED_MD5}" ]; then
    logmsg "C" "patch" "patchinfo=\"/etc/prettyversion.txt\"" "checksum failure"
    
    _CURRENT_MD5=`md5sum /etc/prettyversion.txt | awk '{ print $1; }'`
    logmsg "I" "patch" "current_md5=${_CURRENT_MD5},expected_md5=${_EXPECTED_MD5},patch_md5=${_PATCH_MD5}" "checksum verify"

    return 1
  fi

  chmod 755 patch/etc/prettyversion.txt
  rm -f 000.prettyversion.txt.patch

  update_percent_complete 1

  logmsg "I" "patch" "patchinfo=\"/etc/version.txt\"" "patching file"

  mkdir -p patch/etc/
  bspatch /etc/version.txt patch/etc/version.txt 001.version.txt.patch
  if [ $? -ne 0 ]; then
    logmsg "C" "patch" "patchinfo=\"/etc/version.txt\"" "patch failure"
    return 1
  fi

  _PATCH_MD5=`md5sum patch/etc/version.txt | awk '{ print $1; }'`
  _EXPECTED_MD5=6f8ff921779167cc36fceb43acc9a415
  if [ ! "${_PATCH_MD5}" = "${_EXPECTED_MD5}" ]; then
    logmsg "C" "patch" "patchinfo=\"/etc/version.txt\"" "checksum failure"
    
    _CURRENT_MD5=`md5sum /etc/version.txt | awk '{ print $1; }'`
    logmsg "I" "patch" "current_md5=${_CURRENT_MD5},expected_md5=${_EXPECTED_MD5},patch_md5=${_PATCH_MD5}" "checksum verify"

    return 1
  fi

  chmod 644 patch/etc/version.txt
  rm -f 001.version.txt.patch

  update_percent_complete 1

  logmsg "I" "update" "updating device with patches"

  cd patch
  tar cf - . | (cd / ; tar xvf -)
  _RET=$?
  if [ ${_RET} -ne 0 ]; then
    logmsg "C" "update0" "code=${_RET}" "failure updating device with patches"
    return 1
  fi

  cd - >/dev/null
  rm -rf patch


  logmsg "I" "update" "updating device with symlink deletes"


  logmsg "I" "update" "updating device with symlink changes"

    logmsg "I" "update" "updating device with new rootfs_md5_list"

    tar zxvf rootfs_md5_list.tar.gz && rm -f rootfs_md5_list.tar.gz
    cp rootfs_md5_list /test/diags/factory/ && rm -f rootfs_md5_list

  return 0
}

_TMPFS_SIZE=`df -h /var | awk '/mnt/ { print $2 }' | sed 's/\.[0-9]M//g'`
if [ -n "${_TMPFS_SIZE}" ]; then
  if [ ${_TMPFS_SIZE} -lt 32 ]; then
    _TMPFS_SIZE=32
  fi
else
  _TMPFS_SIZE=32
fi

mount -o remount,size=64M /var

[ -f update-patches.tar.gz ] && tar xzvf update-patches.tar.gz && rm -f update-patches.tar.gz
[ -f update-adds.tar.gz ] && tar xzvf update-adds.tar.gz && rm -f update-adds.tar.gz

_COPY_ERROR=0
_COPY_ERROR_FILES=""
perform_patches
_RET=$?

mount -o remount,size=${_TMPFS_SIZE}M /var

if [ ${_RET} -ne 0 ]; then
  return ${_RET}
fi


if [ ${_COPY_ERROR} -ne 0 ] && [ 0 -ne 0 ];then
  logmsg "C" "md5-error" "errorfiles=${_COPY_ERROR_FILES}" "issues copying to disk"
  return ${_COPY_ERROR}
fi

logmsg "I" "done" "id=`basename $0 .ffs`,version=`cat /etc/version.txt | awk /System/\ '{ print $4 }'`" "update complete"

update_progressbar 100

return 0

