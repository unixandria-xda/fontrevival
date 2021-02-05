# shellcheck shell=ash
if test "$(getenforce)" == "Enforcing" || test "$(getenforce)" == "enforcing"
then
    setenforce 0
    IS_ENFORCE=true
fi

do_banner () {
cat << "EOF" 
  ___ ___  _  _ _____ ___ ___ ___ ___ ___ 
 | __/ _ \| \| |_   _|_ _| __|_ _| __| _ \
 | _| (_) | .` | | |  | || _| | || _||   /
 |_| \___/|_|\_| |_| |___|_| |___|___|_|_\

EOF
sleep 2
}
do_banner
ui_print "- Welcome to Fontifier!"
ui_print "- Setting up enviroment..."
dl () {
      mkdir -p "$MODPATH"/system/etc/security
    if [ -f "/system/etc/security/ca-certificates.crt" ]; then
      cp -f /system/etc/security/ca-certificates.crt "$MODPATH"/ca-certificates.crt
    else
      for i in /system/etc/security/cacerts*/*.0; do
        sed -n "/BEGIN CERTIFICATE/,/END CERTIFICATE/p" "$i" >> "$MODPATH"/ca-certificates.crt
      done
    fi
    "$MODPATH"/common/tools/aria2c-"$ARCH" -x 16 -s 16 --async-dns --file-allocation=none --check-certificate=false --ca-certificate="$MODPATH"/ca-certificates.crt --quiet "$@"
}
mkdir "$MODPATH"/tools
cp_ch "$MODPATH"/common/tools/aria2c-"$ARCH" "$MODPATH"/tools/aria2c
test_connection() {
  ui_print "- Testing internet connectivity"
  (ping -4 -q -c 1 -W 2 linuxandria.com >/dev/null 2>&1) && return 0 || return 1
}
get_lists () {
    test_connection
    if test $? -ne 0;
    then
        ui_print "- No internet access!"
        ui_print "- This module requires internet access."
        ui_print "- There is no current plans for making it work offline, as it requires certain online files."
        ui_print "- Aborting"
        abort
    else
        ui_print "- Excellent, you have internet."
        ui_print "- Downlading extra files..."
        mkdir -p "$MODPATH"/lists
        dl https://downloads.linuxandria.com/downloads/fontifier-files/lists/fonts-list.txt -d "$TMPDIR"
        dl https://downloads.linuxandria.com/downloads/fontifier-files/lists/emojis-list.txt -d "$TMPDIR"
        dl https://downloads.linuxandria.com/downloads/fontifier-files/xml/fonts.xml -d "$TMPDIR"
    fi
}
copy_lists () {
    mkdir -p /sdcard/Fontifier/lists
    mkdir -p /sdcard/Fontifier/font
    mkdir -p /sdcard/Fontifier/emoji
    cp "$TMPDIR"/*-list.txt /sdcard/Fontifier/lists
    cp "$TMPDIR"/*-list.txt "$MODPATH"/lists
    cp "$TMPDIR"/fonts.xml "$MODPATH"/"$(find /*/etc/ | grep fonts.xml)"
}
setup_script () {
    chmod 755 "$MODPATH"/system/bin/fontifier
    chmod 755 "$MODPATH"/system/bin/fontifier.sh
    mkdir "$MODPATH"/system/fonts
}
extra_cleanup () {
  rm -rf "$MODPATH"/*.md
  rm -rf "$MODPATH"/LICENSE
}
get_lists
copy_lists
setup_script
extra_cleanup
if $IS_ENFORCE
    then
        setenforce 1
fi
ui_print "⚠ Please make sure not to have any other font changing modules installed ⚠"
ui_print "⚠ Please remove any such module, as it conflicts with Fontifier ⚠"