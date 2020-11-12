# shellcheck shell=dash
ui_print "- Welcome to fontrevival!"
ui_print "- Setting up enviroment..."
alias busybox='$MODPATH/common/tools/busybox-$ARCH-selinux'
dl () {
    "$MODPATH"/common/tools/aria2c-"$ARCH" -x 16 --async-dns "$@"
}
cp_ch "$MODPATH"/common/tools  "$MODPATH"/tools/
test_connection() {
  ui_print "- Testing internet connectivity"
  (ping -4 -q -c 1 -W 1 bing.com >/dev/null 2>&1) && return 0 || return 1
}
get_lists () {
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
    dl https://downloads.linuxandria.com/downloads/fontrevival/fonts-list.txt
    dl https://downloads.linuxandria.com/downloads/fontrevival/emojis-list.txt
fi
}
copy_lists () {
    mkdir -p "$MODPATH"/lists
    sed -i s/Font_//g "$MODPATH"/*-list.txt
    sed -i s/\.zip//g "$MODPATH"/*-list.txt
    cp "$MODPATH"/*-list.txt "$MODPATH"/lists
}
setup_script () {
    mv "$MODPATH"/system/bin/fontrevive.sh "$MODPATH"/system/bin/fontrevive
    chmod 755 "$MODPATH"/system/bin/fontrevive
    mkdir "$MODPATH"/system/fonts
}
get_lists
copy_lists
setup_script