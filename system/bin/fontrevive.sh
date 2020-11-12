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
exec 3>&2 2> /sdcard/FontRevival/logs/main-verbose.log
set -x 2
set -euo pipefail
trap 'exxit $?' EXIT
clear
cat << "EOF" 
  ____            __   ___              _              __
  / __/___   ___  / /_ / _ \ ___  _  __ (_)_  __ ___ _ / /
 / _/ / _ \ / _ \/ __// , _// -_)| |/ // /| |/ // _ `// / 
/_/   \___//_//_/\__//_/|_| \__/ |___//_/ |___/ \_,_//_/  
                                                          
EOF
sleep 2
echo "Please wait, setting up enviroment..."
alias busybox='$MODDIR/tools/busybox-$ARCH-selinux'
test_connection() {
  ui_print "- Testing internet connectivity"
  (ping -4 -q -c 1 -W 1 bing.com >/dev/null 2>&1) && return 0 || return 1
}
dl () {
    "$MODDIR"/tools/aria2c -x 16 --async-dns  --check-certificate=false --ca-certificate=/system/etc/security/ca-certificates.crt --quiet "$@"
}
font_select () {
    clear
    sleep 0.5
   printf '\n%s\n' "Fonts selected."
    sleep 0.5
    printf '\n%s\n' "Please type the name of the font you would like to apply from this list:"
    sleep 3
    awk '{  a[i++] = $0
        if (i == 3)
        {
            printf "%-14s  %-14s  %-14s\n", a[0], a[1], a[2]
            i = 0
        }
     }
     END {
        if (i > 0)
        {
            printf "%-14s", a[0]
            for (j = 1; j < i; j++)
                printf "  %-14s", a[j]
            printf "\n"
        }
     }' "$MODDIR"/lists/fonts-list.txt
    sleep 1
   printf '\n%s\n' "Your choice:"
    read -r a
    if test $? -ne 0;
    then
        ui_print "- No internet access!"
        ui_print "- For now this module requires internet access"
        ui_print "- Aborting"
        exit 1
    else
        dl https://downloads.linuxandria.com/downloads/fontrevival/font/Font_"$a".zip -d /sdcard/FontRevival/
        if test $? -ne 0
        then
            # They probably mistyped something and we're getting a 404
            clear
            printf '\n%s\n' "ERROR: INVALID SELECTION"
            sleep 0.5
            printf '\n%s\n' "Please try again"
            sleep 5
            font_select
        else
            clear
            sleep 0.2
            printf '\n%s\n' "Now installing the font..."
            sleep 2
            unzip /sdcard/FontRevival/Font_"$a".zip -d "$MODDIR/system/fonts"
            printf '\n%s\n' "Install success!"
            sleep 2
        fi
    fi
    menu_set
}
emoji_select () {
    clear
    sleep 0.5
    printf '\n%s\n' "Emojis selected."
    sleep 0.5
   printf '\n%s\n' "Please type the name of the emoji you would like to apply from this list:"
    sleep 3
    awk '{  a[i++] = $0
        if (i == 5)
        {
            printf "%-14s  %-14s  %-14s\n", a[0], a[1], a[2]
            i = 0
        }
     }
     END {
        if (i > 0)
        {
            printf "%-14s", a[0]
            for (j = 1; j < i; j++)
                printf "  %-14s", a[j]
            printf "\n"
        }
     }' "$MODDIR"/lists/emojis-list.txt
    sleep 1
    printf '\n%s\n' "Your choice:"
    read -r a
    if test $? -ne 0;
    then
        ui_print "- No internet access!"
        ui_print "- For now this module requires internet access"
        ui_print "- Aborting"
        exit 1
    else
        dl https://downloads.linuxandria.com/downloads/fontrevival/emoji/Emoji_"$a".zip -d /sdcard/FontRevival/
        if test $? -ne 0
        then
            # They probably mistyped something and we're getting a 404
            clear
            printf '\n%s\n' "ERROR: INVALID SELECTION"
            sleep 0.5
            printf '\n%s\n' "Please try again"
            sleep 5
            emoji_select
        else
            clear
            sleep 0.2
            printf '\n%s\n' "Now installing the emoji..."
            sleep 2
            unzip /sdcard/FontRevival/Emoji_"$a".zip -d "$MODDIR/system/fonts"
            printf '\n%s\n' "Install success!"
            sleep 2

        fi
    fi
    menu_set
}
menu_set () {
while :
do
clear
echo "-- MAIN MENU --"
printf '\n%s\n' "1. Fonts"
printf '\n%s\n' "2. Emojis"
printf '\n%s\n' "3. Quit"
printf '\n%s\n' "Please choose an option:"
read -r a
case $a in
1* )     font_select ;;
2* )     emoji_select ;;
3* )     exit 0;;
* )     echo "Try again." && sleep 2 && menu_set ;;
esac
done
}
ls /data/adb/modules/*/system/fonts/ | grep -v fontrevival >/dev/null
if test $? -eq 0
then
    printf '\n%s\n' '!!! WARNING !!!'
    printf '\n%s\n' 'Potentially conflciting module detected'
    printf '\n%s\n' 'Before reporting bugs please remove any other module that effects fonts'
    sleep 10
    clear
    menu_set
else
    menu_set
fi


