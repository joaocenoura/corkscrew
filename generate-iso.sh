#!/bin/bash -e
BASE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TMP="$BASE/tmp"
TMP_INSTALLERS="$TMP/installers"
LATEST_INSTALLER="$TMP_INSTALLERS/latest"
WORKSPACE="${WORKSPACE:-$BASE/workspace}"
CD_DIR="$WORKSPACE/cd"
mkdir -p $TMP_INSTALLERS $WORKSPACE

################################################################################
# core functions
################################################################################
function header {
    echo
    echo "============================================================"
    echo "  $1"
    echo "============================================================"
}

function log_info {
    echo "[$1] $2"
}

function log_warn {
    echo "[$1] $2"
}

function log_error {
    echo "[$1] $2"
}

function relative_basepath_for {
    echo "$(realpath $1 --relative-to $BASE)"
}

################################################################################
# phase functions
################################################################################
function load_configuration {
    header "load configuration"
    if [ -z "$1" ]; then
        log_error "load_configuration" "expected configuration file as input"
        exit 10
    elif [ ! -f "$1" ]; then
        log_error "load_configuration" "configuration file not found: $1"
        exit 11
    fi

    log_info "load_configuration" "from: $(relative_basepath_for $1)"
    source $1
    CONF_DIR=$(dirname "$1")
}

function validate_configuration {
    header "validate configuration"

    if [[ ! "$PRESEED_FILE" = /* ]]; then
        PRESEED_FILE="$CONF_DIR/$PRESEED_FILE"
    fi

    log_info "validate_configuration" "PRESEED_FILE=$PRESEED_FILE"
    log_warn "validate_configuration" "TBD"
}

function download_installer {
    header "download installer"
    local installer_name="$(basename $INSTALLER_URL)"
    local installer_path="$TMP_INSTALLERS/$installer_name"

    if [ ! -f "$installer_path" ]; then
        log_info "download_installer" "$installer_name doesn't exist... downloading"
        log_info "download_installer" "downloading installer if necessary"
        log_info "download_installer" "from: $INSTALLER_URL"
        log_info "download_installer" "  to: $(relative_basepath_for $installer_path)"

        tmp_file=$(mktemp)
        wget -q --show-progress "$INSTALLER_URL" -O $tmp_file
        mv $tmp_file $installer_path
    else
        log_info "download_installer" "reusing installer"
        log_info "download_installer" "timestamp: $(date -r $installer_path)"
        log_info "download_installer" "     from: $(relative_basepath_for $installer_path)"
    fi
    ln -sf $installer_path $LATEST_INSTALLER
}

function clean_workspace {
    header "clean workspace"

    if [ -d "$CD_DIR" ]; then
        log_info "clean_workspace" "removing $(relative_basepath_for $CD_DIR)/*"
        chmod +w -R $CD_DIR
        rm -rf $CD_DIR
    fi
    log_info "clean_workspace" "mkdir $(relative_basepath_for $CD_DIR)"
    mkdir $CD_DIR
}

function unpack_installer {
    header "unpack installer"
    log_info "unpack_installer" "installer: $(relative_basepath_for $LATEST_INSTALLER)"
    log_info "unpack_installer" "       to: $(relative_basepath_for $CD_DIR)"

    bsdtar -C $CD_DIR -xf $LATEST_INSTALLER
}

function preseed_installer {
    header "preseed installer"

    cp $PRESEED_FILE $TMP/preseed.cfg

    chmod +w $CD_DIR/install.amd                 # allow us to write temporarily
    gunzip $CD_DIR/install.amd/initrd.gz         # unpack initrd
    chmod +w $CD_DIR/install.amd/initrd          # allow us to write temporarily
    cd $TMP && echo "preseed.cfg" | cpio -o -H newc -A -F $CD_DIR/install.amd/initrd
    chmod -w $CD_DIR/install.amd/initrd          # revert to write protected
    gzip $CD_DIR/install.amd/initrd              # pack initrd with our preseed
    chmod -w $CD_DIR/install.amd                 # revert to write protected
}

function customize_installer {
    header "customize installer"

    # small customization line to give quick feedback about the current build
    chmod +w $CD_DIR/isolinux
    sed -i "s#Install#Install `date +%Y-%m-%d:%H:%M:%S`#g" $CD_DIR/isolinux/txt.cfg
    chmod -w $CD_DIR/isolinux
}

function rewrite_md5sum {
    header "rewrite md5sum.txt"

    chmod +w $CD_DIR/md5sum.txt
    cd $CD_DIR; md5sum `find ! -name "md5sum.txt" ! -path "./isolinux/*" -follow -type f` > $CD_DIR/md5sum.txt
    chmod -w $CD_DIR/md5sum.txt
}

function generate_cd {
    header "generate CD"

    local output="$WORKSPACE/${INSTALLER_NAME}.iso"

    log_info "generate_cd" "output: $output"
    xorriso -as mkisofs -o $output \
            -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
            -c isolinux/boot.cat -b isolinux/isolinux.bin \
            -no-emul-boot -boot-load-size 4 -boot-info-table $CD_DIR
}


################################################################################
#  ENTRY POINT
################################################################################

# argument parsing
load_configuration "$1"
validate_configuration

# prepare
download_installer
clean_workspace
unpack_installer

# tasks
preseed_installer
customize_installer

# finalize
rewrite_md5sum
generate_cd
