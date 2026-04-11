#!/bin/sh -e
#
# $Id: build-updates.sh 16160 2019-07-12 02:33:13Z NiLuJe $
#

HACKNAME="jailbreak"
HACKDIR="linkjail"
PKGNAME="${HACKNAME}"
PKGVER="0.13.N"

# Do we have kindletool (https://github.com/NiLuJe/KindleTool) in $PATH?
if kindletool help &>/dev/null ; then
	USE_KINDLETOOL="true"
fi

# We also need GNU tar
if [[ "$(uname -s)" == "Darwin" ]] ; then
	TAR_BIN="gtar"
else
	TAR_BIN="tar"
fi
if ! ${TAR_BIN} --version | grep -q "GNU tar" ; then
	echo "You need GNU tar to build this package."
	exit 1
fi

# Force use of the python tool
#USE_KINDLETOOL="false"

# Pickup our common stuff... We leave it in our staging wd so it ends up in the source package.
if [[ ! -d "../../Common" ]] ; then
	echo "The tree isn't checked out in full, missing the Common directory..."
	exit 1
fi
# LibOTAUtils
ln -f ../../Common/lib/libotautils ./libotautils
# LibKH
for common_lib in libkh ; do
	ln -f ../../Common/lib/${common_lib} ../src/${HACKDIR}/bin/${common_lib}
done


# FW 2.x
KINDLE_MODELS="k2 k2i dx dxi dxg"
for model in ${KINDLE_MODELS} ; do
	# Prepare our files for this specific kindle model...
	ARCH=${PKGNAME}_${PKGVER}_${model}

	ln -f 2.5-${HACKNAME}.dat update_${ARCH}.dat
	ln -f 2.5-install.sh install.sh
	ln -f 2.5-install.sh.sig install.sh.sig

	# Build install update
	${TAR_BIN} --hard-dereference --owner root --group root -cvzf ${ARCH}.tgz install.sh install.sh.sig update-adds.tar.gz update_${ARCH}.dat

	if [[ "$USE_KINDLETOOL" == "true" ]] ; then
		kindletool create ota -d ${model} ${ARCH}.tgz Update_${ARCH}_install.bin
	else
		./kindle_update_tool.py c --${model} ${ARCH}_install ${ARCH}.tgz
	fi

	# Cleanup our temp model-specific files
	rm -rf ${ARCH}.tgz update_${ARCH}.dat install.sh install.sh.sig

	if [[ "$USE_KINDLETOOL" == "true" ]] ; then
		# Uninstall
		kindletool create ota -d ${model} uninstall.sh Update_${ARCH}_uninstall.bin
	else
		# Build uninstall update
		./kindle_update_tool.py m --sign --${model} ${ARCH}_uninstall uninstall.sh
	fi
done

# FW 3.0.x
KINDLE_MODELS="k3g k3w k3gb"

#for model in ${KINDLE_MODELS} ; do
#	# Prepare our files for this specific kindle model...
#	ARCH=${PKGNAME}_${PKGVER}_${model}
#
#	ln -f 3.0-${HACKNAME}.dat update_${ARCH}.dat
#	ln -f 3.0-${HACKNAME}.dat.sig update_${ARCH}.dat.sig
#	ln -f 3.0-install.sh 3.0-jb-sig
#	ln -sf 3.0-jb-sig 490480060-490488060.ffs
#
#	# Build install update
#	${TAR_BIN} --hard-dereference --owner root --group root -cvzf ${ARCH}.tgz 490480060-490488060.ffs update_${ARCH}.dat update_${ARCH}.dat.sig 3.0-jb-sig
#	./kindle_update_tool.py c --${model} ${ARCH}_install ${ARCH}.tgz
#
#	# Cleanup our temp model-specific files
#	rm -rf ${ARCH}.tgz update_${ARCH}.dat update_${ARCH}.dat.sig 3.0-jb-sig 490480060-490488060.ffs
#
#	# Build uninstall update
#	./kindle_update_tool.py m --sign --${model} ${ARCH}_uninstall uninstall.sh
#done

# FW 3.0-3.2. Credits goes to yifanlu for this one, thanks! (http://yifan.lu/p/kindle-jailbreak)
# Archive custom directory
${TAR_BIN} --hard-dereference --owner root --group root --exclude-vcs -cvzf ${HACKDIR}.tgz.sig ../src/${HACKDIR}

for model in ${KINDLE_MODELS} ; do
	# Prepare our files for this specific kindle model, and add a -3.0-to-3.2 tag to denote the fact that it will only run on hese specific FW versions ...
	BASE_ARCH=${PKGNAME}_${PKGVER}_${model}
	ARCH=${BASE_ARCH}-3.0-to-3.2

	ln -f "3.0-${HACKNAME}.dat" "update ${ARCH}.sig .dat"
	ln -f "3.0-${HACKNAME}.dat.sig" "update ${ARCH}.sig .dat.sig"
	ln -f 3.1-install.sh 3.1-jb.sig
	ln -f linkjail-init linkjail-init.sig

	# Build our bundle file
	if [[ "$(uname -s)" == "Darwin" ]] ; then
		jb_md5sum=$( md5 -q 3.1-jb.sig )
		jb_blocks=$(( $( stat -f %z 3.1-jb.sig ) / 64 ))
	else
		jb_md5sum=$( md5sum 3.1-jb.sig | awk '{ print $1; }' )
		jb_blocks=$(( $( stat -c %s 3.1-jb.sig ) / 64 ))
	fi
	echo "129 ${jb_md5sum} 3.1-jb.sig ${jb_blocks} 3.1-jb" > "${ARCH}.sig"

	# Build install update
	${TAR_BIN} --hard-dereference --owner root --group root -cvzf ${ARCH}.tgz "update ${ARCH}.sig .dat" "update ${ARCH}.sig .dat.sig" "${ARCH}.sig" "3.1-jb.sig" "${HACKDIR}.tgz.sig" "linkjail-init.sig"

	if [[ "$USE_KINDLETOOL" == "true" ]] ; then
		kindletool create ota -d ${model} ${ARCH}.tgz Update_${ARCH}_install.bin
	else
		./kindle_update_tool.py c --${model} ${ARCH}_install ${ARCH}.tgz
	fi

	# Cleanup our temp model-specific files
	rm -rf ${ARCH}.tgz "update ${ARCH}.sig .dat" "update ${ARCH}.sig .dat.sig" "${ARCH}.sig" "3.1-jb.sig" "linkjail-init.sig"

	if [[ "$USE_KINDLETOOL" == "true" ]] ; then
		kindletool create ota -d ${model} libotautils 3.1-uninstall.sh Update_${BASE_ARCH}_uninstall.bin
	else
		# Build uninstall update
		./kindle_update_tool.py m --sign --${model} ${BASE_ARCH}_uninstall libotautils 3.1-uninstall.sh
	fi
done

# FW 3.2.1-3.4. Credits goes to yifanlu & serge_levin for this one, thanks! (http://yifan.lu/p/kindle-jailbreak / http://www.mobileread.com/forums/showpost.php?p=1725629&postcount=151)
# NOTE: We need to build *BOTH*, because this one won't run on anything except >= v3.2.1

for model in ${KINDLE_MODELS} ; do
	# Prepare our files for this specific kindle model...
	ARCH=${PKGNAME}_${PKGVER}_${model}

	ln -f "3.0-${HACKNAME}.dat" "updatedat"
	ln -f "3.0-${HACKNAME}.dat.sig" "updatedat.sig"
	ln -f 3.1-install.sh 3.2.1-jb.sig
	ln -f linkjail-init linkjail-init.sig

	# Build our bundle file
	if [[ "$(uname -s)" == "Darwin" ]] ; then
		jb_md5sum=$( md5 -q 3.2.1-jb.sig )
		jb_blocks=$(( $( stat -f %z 3.2.1-jb.sig ) / 64 ))
	else
		jb_md5sum=$( md5sum 3.2.1-jb.sig | awk '{ print $1; }' )
		jb_blocks=$(( $( stat -c %s 3.2.1-jb.sig ) / 64 ))
	fi
	echo "129 ${jb_md5sum} 3.2.1-jb.sig ${jb_blocks} 3.2.1-jb" > "update\dat"

	# Build install update
	${TAR_BIN} --hard-dereference --owner root --group root -cvzf ${ARCH}.tgz "updatedat" "updatedat.sig" "update\dat" "3.2.1-jb.sig" "${HACKDIR}.tgz.sig" "linkjail-init.sig"

	if [[ "$USE_KINDLETOOL" == "true" ]] ; then
		kindletool create ota -d ${model} ${ARCH}.tgz Update_${ARCH}_install.bin
	else
		./kindle_update_tool.py c --${model} ${ARCH}_install ${ARCH}.tgz
	fi

	# Cleanup our temp model-specific files
	rm -rf ${ARCH}.tgz "updatedat" "updatedat.sig" "update\dat" "3.2.1-jb.sig" "linkjail-init.sig"

	# Build uninstall update (Same as before, so don't package it twice)
	#./kindle_update_tool.py m --sign --${model} ${ARCH}_uninstall 3.1-uninstall.sh
done

# Remove custom directory archive
rm -f ${HACKDIR}.tgz.sig

# Move our updates :)
mv -f *.bin ../
