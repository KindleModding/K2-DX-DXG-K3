#!/bin/sh

echo "==========================="
echo "=  K3 Jailbreak Builder   ="
echo "=  Created by Hackerdude  ="
echo "= (Based on NiLuJe's JB)  ="
echo "==========================="

rm -rf build_tmp/k3_3.0-3.2
rm -rf build/k3_3.0-3.2
mkdir -p build_tmp/k3_3.0-3.2
mkdir -p build/k3_3.0-3.2

rm -rf build_tmp/k3_3.2.1
rm -rf build/k3_3.2.1
mkdir -p build_tmp/k3_3.2.1
mkdir -p build/k3_3.2.1

set -e

echo "[*] Building linkjail..."
tar --hard-dereference --owner root --group root --exclude-vcs --transform="flags=r;s|src/k3/install/linkjail|src|" -cvzf ./build_tmp/k3_3.0-3.2/linkjail.tgz.sig src/k3/install/linkjail/

echo "[*] Building for 3.0-3.2..."

echo "[*] Copying files..."
cp -ar "./src/k3/install/3.0-jailbreak.dat" "./build_tmp/k3_3.0-3.2/update jailbreak.sig .dat"
cp -ar "./src/k3/install/3.0-jailbreak.dat.sig" "./build_tmp/k3_3.0-3.2/update jailbreak.sig .dat.sig"
cp -ar "./src/k3/install/install.sh" "./build_tmp/k3_3.0-3.2/3.1-jb.sig"
cp -ar "./src/k3/install/linkjail-init" "./build_tmp/k3_3.0-3.2/linkjail-init.sig"

# Build our bundle file
jb_md5sum=$( md5sum ./build_tmp/k3_3.0-3.2/3.1-jb.sig | awk '{ print $1; }' )
jb_blocks=$(( $( stat -c %s ./build_tmp/k3_3.0-3.2/3.1-jb.sig ) / 64 ))
echo "129 ${jb_md5sum} 3.1-jb.sig ${jb_blocks} 3.1-jb" > "./build_tmp/k3_3.0-3.2/jailbreak_3.0-to-3.2.sig"

KINDLE_MODELS="k3g k3w k3gb"

for model in ${KINDLE_MODELS} ; do
	# Build install update
	tar --hard-dereference --owner root --group root -cvzf "build/k3_3.0-3.2/${model}.tgz" \
        --transform="flags=r;s|./build_tmp/k3_3.0-3.2/||" \
        --transform="flags=r;s|update jailbreak.sig .dat|update jailbreak_${model}_3.0-to-3.2.sig .dat|" \
        --transform="flags=r;s|update jailbreak.sig .dat.sig|update jailbreak_${model}_3.0-to-3.2.sig .dat.sig|" \
        --transform="flags=r;s|jailbreak_3.0-to-3.2.sig|jailbreak_${model}_3.0-to-3.2.sig|" \
        ./build_tmp/k3_3.0-3.2/*

    kindletool create ota -d ${model} "build/k3_3.0-3.2/${model}.tgz" build/k3_3.0-3.2/Update_jailbreak_${model}_3.0-to-3.2_install.bin
    rm "build/k3_3.0-3.2/${model}.tgz"
    cd src/k3/uninstall
        kindletool create ota -d ${model} ./* ../../../build/k3_3.0-3.2/Update_jailbreak_${model}_uninstall.bin
    cd ../../../
done

# FW 3.2.1-3.4. Credits goes to yifanlu & serge_levin for this one, thanks! (http://yifan.lu/p/kindle-jailbreak / http://www.mobileread.com/forums/showpost.php?p=1725629&postcount=151)
# NOTE: We need to build *BOTH*, because this one won't run on anything except >= v3.2.1

echo "[*] Building for 3.2.1+ ..."

echo "[*] Copying files..."
cp ./build_tmp/k3_3.0-3.2/linkjail.tgz.sig ./build_tmp/k3_3.2.1/linkjail.tgz.sig
cp -ar "./src/k3/install/3.0-jailbreak.dat" "./build_tmp/k3_3.2.1/updatedat"
cp -ar "./src/k3/install/3.0-jailbreak.dat.sig" "./build_tmp/k3_3.2.1/updatedat.sig"
cp -ar "./src/k3/install/install.sh" "./build_tmp/k3_3.2.1/3.2.1-jb.sig"
cp -ar "./src/k3/install/linkjail-init" "./build_tmp/k3_3.2.1/linkjail-init.sig"

# Build our bundle file
jb_md5sum=$( md5sum ./build_tmp/k3_3.2.1/3.2.1-jb.sig | awk '{ print $1; }' )
jb_blocks=$(( $( stat -c %s ./build_tmp/k3_3.2.1/3.2.1-jb.sig ) / 64 ))
echo "129 ${jb_md5sum} 3.2.1-jb.sig ${jb_blocks} 3.2.1-jb" > "./build_tmp/k3_3.2.1/update\dat"

for model in ${KINDLE_MODELS} ; do
	# Build install update
	tar --hard-dereference --owner root --group root -cvzf "build/k3_3.2.1/${model}.tgz" \
        --transform="flags=r;s|./build_tmp/k3_3.2.1/||" \
        "./build_tmp/k3_3.2.1/updatedat" \
        "./build_tmp/k3_3.2.1/updatedat.sig" \
        "./build_tmp/k3_3.2.1/update\dat" \
        "./build_tmp/k3_3.2.1/3.2.1-jb.sig" \
        "./build_tmp/k3_3.2.1/linkjail.tgz.sig" \
        "./build_tmp/k3_3.2.1/linkjail-init.sig"

    kindletool create ota -d ${model} "build/k3_3.2.1/${model}.tgz" "./build/k3_3.2.1/Update_${model}_install.bin"
    rm "build/k3_3.2.1/${model}.tgz"
done

echo "Done."