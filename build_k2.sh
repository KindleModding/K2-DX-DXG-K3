#!/bin/sh

echo "==========================="
echo "=  K2 Jailbreak Builder   ="
echo "=  Created by Hackerdude  ="
echo "= (Based on NiLuJe's JB)  ="
echo "==========================="

rm -rf build_tmp/k2
rm -rf build/k2
mkdir -p build_tmp/k2
mkdir -p build/k2

set -e

echo "[*] Building update-adds payload..."
tar -czf ./build_tmp/k2/update-adds.tar.gz \
    --transform='flags=r;s|src/k2/payload/root_link|root|' \
    --transform='flags=r;s|src/k2/payload/||' \
    --owner=root --group=root \
    src/k2/payload/root_link \
    src/k2/payload/root/etc/uks/pubhackkey01.pem \
    src/k2/payload/root/var/local/java/keystore/developer.keystore \
    src/k2/payload/root/opt/amazon/ebook/lib/json_simple-1.1.jar

echo "[*] Copying files..."
cp -ra src/k2/install/* build_tmp/k2/

echo "[*] Building JB update files"
KINDLE_MODELS="k2 k2i dx dxi dxg"
for model in ${KINDLE_MODELS} ; do
	# Prepare our files for this specific kindle model...
	ARCH=${model}

	# Build install update
	tar --hard-dereference \
        --owner root --group root \
        -cvzf build/k2/${ARCH}.tgz \
        --transform='flags=r;s|build_tmp/k2/||' \
        --transform="flags=r;s|2.5-jailbreak.dat|update-filelist.dat|" \
        --transform="flags=r;s|2.5-install.sh|install.sh|" \
        --transform="flags=r;s|2.5-install.sh.sig|install.sh.sig|" \
        build_tmp/k2/*

    kindletool create ota -d ${model} -xPackageName="NiLuJe Jailbreak" -xPackageVersion="v1.0.0" -xPackageAuthor="NiLuJe, yifanlu" -xPackageMaintainer="Hackerdude, NiLuJe" build/k2/${ARCH}.tgz build/k2/Update_${ARCH}_install.bin
    rm build/k2/${ARCH}.tgz
    cd src/k2/uninstall/
        kindletool create ota -d ${model} ./* ../../../build/k2/Update_${ARCH}_uninstall.bin
    cd ../../../
done

echo "Done."