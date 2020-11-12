#!/data/adb/modules/fontrevival/tools/busybox ash
# shellcheck shell=dash
mkdir -p /sdcard/FontRevival/logs
# Ugly, I hate hardcoding but what else can I do here?
MODDIR="/data/adb/modules/fontrevival"
exxit() {
	  set +euxo pipefail
	    [ "$1" -ne 0 ] && abort "$2"
	      exit "$1"
      }
exec 3>&2 2> /sdcard/FontRevival/logs/service-verbose.log
set -x 2
set -euo pipefail
trap 'exxit $?' EXIT
echo "Please wait, setting up enviroment..."
alias busybox='$MODDIR/tools/busybox-$ARCH-selinux'
ls /data/adb/modules/*/system/fonts/
if test $? -eq 0
then
    printf "!!! WARNING !!!"
    printf "Potentially conflciting module detected"
    printf "Before reporting bugs please remove any other module that effects fonts"
    sleep 10
    clear
fi
test_connection() {
  ui_print "- Testing internet connectivity"
  (ping -4 -q -c 1 -W 1 bing.com >/dev/null 2>&1) && return 0 || return 1
}
dl () {
    "$MODDIR"/tools/aria2c-"$ARCH" -x 16 --async-dns "$@"
}
font_select () {
    clear
    sleep 0.5
    echo -n "Fonts selected."
    sleep 0.5
    echo -n "Please type the name of the font you would like to apply from this list:"
    sleep 3
    printf '%b\n' "$(cat "$MODPATH"/lists/fonts-list.txt)" 
    sleep 1
    echo -n "Your choice:"
    read -r 1 -t 15 a
    printf "\n"
    if test $? -ne 0;
    then
        ui_print "- No internet access!"
        ui_print "- For now this module requires internet access"
        ui_print "- Aborting"
        exit 1
    else
        dl https://downloads.linuxandria.com/downloads/fontrevival/font/Font_"$a".zip
        if test $? -ne 0
        then
            # They probably mistyped something and we're getting a 404
            clear
            printf "ERROR: INVALID SELECTION"
            sleep 0.5
            printf "Please try again"
            sleep 5
            font_select
        else
            clear
            sleep 0.2
            printf "Now installing the font..."
            sleep 2
            mv Font_"$a".zip /sdcard/FontRevival
            unzip /sdcard/FontRevival/Font_"$a".zip -d "$MODPATH/system/fonts"
        fi
    fi
}
emoji_select () {
    clear
    sleep 0.5
    echo -n "Emojis selected."
    sleep 0.5
    echo -n "Please type the name of the emoji you would like to apply from this list:"
    sleep 3
    printf '%b\n' "$(cat "$MODPATH"/lists/emojis-list.txt)" 
    sleep 1
    echo -n "Your choice:"
    read -r 1 -t 15 a
    printf "\n"
    if test $? -ne 0;
    then
        ui_print "- No internet access!"
        ui_print "- For now this module requires internet access"
        ui_print "- Aborting"
        exit 1
    else
        dl https://downloads.linuxandria.com/downloads/fontrevival/emoji/Emoji_"$a".zip
        if test $? -ne 0
        then
            # They probably mistyped something and we're getting a 404
            clear
            printf "ERROR: INVALID SELECTION"
            sleep 0.5
            printf "Please try again"
            sleep 5
            emoji_select
        else
            clear
            sleep 0.2
            printf "Now installing the emoji..."
            sleep 2
            unzip Emoji_"$a".zip -d "$MODPATH/system/fonts"
            unzip /sdcard/FontRevival/Emoji_"$a".zip -d "$MODPATH/system/fonts"
        fi
    fi
}
menu () {
while :
do
clear
echo "1. Fonts"
echo "2. Emojis"
echo "3. Quit"
echo -n "Please choose an option:"
read -r 1 -t 15 a
printf "\n"
case $a in
1* )     font_select ;;
2* )     emoji_select ;;
3* )     exit 0;;
* )     echo "Try again." && sleep 2 && menu ;;
esac
done
}