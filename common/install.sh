# shellcheck shell=dash
ui_print "- Welcome to fontrevival!"
ui_print "- Setting up enviroment..."
alias busybox='$MODPATH/common/tools/busybox-$ARCH-selinux'
dl () {
    "$MODPATH"/common/tools/aria2c-"$ARCH" -x 16 --async-dns  --check-certificate=false --ca-certificate="$MODPATH"/system/etc/security/ca-certificates.crt --quiet "$@"
}
mkdir "$MODPATH"/tools
cp_ch "$MODPATH"/common/tools/busybox-"$ARCH"-selinux "$MODPATH"/tools/busybox
cp_ch "$MODPATH"/common/tools/aria2c-"$ARCH" "$MODPATH"/tools/aria2c
test_connection() {
  ui_print "- Testing internet connectivity"
  (ping -4 -q -c 1 -W 1 bing.com >/dev/null 2>&1) && return 0 || return 1
}
get_lists () {
    mkdir -p "$MODPATH"/system/etc/security
    if [ -f "/system/etc/security/ca-certificates.crt" ]; then
      cp -f /system/etc/security/ca-certificates.crt "$MODPATH"/system/etc/security/ca-certificates.crt
    else
      for i in /system/etc/security/cacerts*/*.0; do
        sed -n "/BEGIN CERTIFICATE/,/END CERTIFICATE/p" "$i" >> "$MODPATH"/system/etc/security/ca-certificates.crt
      done
    fi
    test_connection
    if test $? -ne 0;
    then
        ui_print "- No internet access!"
        ui_print "- For now this module requires internet access"
        ui_print "- Aborting"
        abort
    else
        ui_print "- Excellent, you have internet."
        ui_print "- Downlading extra files..."
        mkdir -p "$MODPATH"/lists
        dl https://downloads.linuxandria.com/downloads/fontrevival/fonts-list.txt -d "$MODPATH"/lists/
        dl https://downloads.linuxandria.com/downloads/fontrevival/emojis-list.txt -d "$MODPATH"/lists/
    fi
}
copy_lists () {
    sed -i s/Font_//g "$MODPATH"/lists/fonts-list.txt
    sed -i s/Emoji_//g "$MODPATH"/lists/emojis-list.txt
    sed -i s/\.zip//g "$MODPATH"/lists/fonts-list.txt
    sed -i s/\.zip//g "$MODPATH"/lists/emojis-list.txt
}
setup_script () {
    mv "$MODPATH"/system/bin/fontrevive.sh "$MODPATH"/system/bin/fontrevive
    chmod 755 "$MODPATH"/system/bin/fontrevive
    mkdir "$MODPATH"/system/fonts
}
get_lists
copy_lists
setup_script