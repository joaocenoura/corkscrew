#!/bin/bash -e
BASE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TMP="$BASE/tmp"
TMP_INSTALLERS="$TMP/installers"
LATEST_INSTALLER="$TMP_INSTALLERS/latest"
WORKSPACE="$BASE/workspace"
CD_DIR="$WORKSPACE/cd"
mkdir -p $TMP_INSTALLERS $WORKSPACE

function get_installer {
    local url=$1
    local installer_name="$(basename $url)"
    local installer_path="$TMP_INSTALLERS/$installer_name"

    if [ ! -f "$installer_path" ]; then
        tmp_file=$(mktemp)
        wget -q --show-progress $url -O $tmp_file
        mv $tmp_file $installer_path
    fi
    ln -sf $installer_path $LATEST_INSTALLER
    echo "$installer_path"
}

################################################################################
# prepare
## argument parsing
installer_url="$1"

if [ ! -z "$installer_url" ]; then
    get_installer $installer_url
fi

if [ -z "$installer_url" ] && [ ! -f "$LATEST_INSTALLER" ]; then
    echo "no installer found"
    exit 1
fi

## clean workspace
if [ -d "$CD_DIR" ]; then
    chmod +w -R $CD_DIR
    rm -rf $CD_DIR
fi
mkdir $CD_DIR

## explode installer
bsdtar -C $CD_DIR -xf $LATEST_INSTALLER

################################################################################
# add preseed.cfg
cp $BASE/preseed.cfg $CD_DIR/preseed.cfg
chmod +w $CD_DIR/isolinux
sed -i 's#append#append file=/cdrom/preseed.cfg#g' $CD_DIR/isolinux/gtk.cfg
sed -i 's#append#append file=/cdrom/preseed.cfg#g' $CD_DIR/isolinux/txt.cfg
chmod -w $CD_DIR/isolinux

chmod +w $CD_DIR/install.amd                     # allow us to write temporarily
gunzip $CD_DIR/install.amd/initrd.gz             # unpack initrd
chmod +w $CD_DIR/install.amd/initrd              # allow us to write temporarily
echo "preseed.cfg" | cpio -o -H newc -A -F $CD_DIR/install.amd/initrd
chmod -w $CD_DIR/install.amd/initrd              # revert to write protected
gzip $CD_DIR/install.amd/initrd                  # pack initrd with our preseed
chmod -w $CD_DIR/install.amd                     # revert to write protected

################################################################################
# finalize
## rewrite md5sum
chmod +w $CD_DIR/md5sum.txt
cd $CD_DIR; md5sum `find ! -name "md5sum.txt" ! -path "./isolinux/*" -follow -type f` > $CD_DIR/md5sum.txt; cd ..
chmod -w $CD_DIR/md5sum.txt

## generate hybrid iso
xorriso -as mkisofs -o $WORKSPACE/test.iso \
        -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
        -c isolinux/boot.cat -b isolinux/isolinux.bin \
        -no-emul-boot -boot-load-size 4 -boot-info-table $CD_DIR

