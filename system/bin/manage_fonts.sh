#!/data/adb/modules/fontrevival/tools/busybox ash
# shellcheck shell=ash
# shellcheck disable=SC2169
# shellcheck disable=SC2034
# shellcheck disable=SC2183
G='\e[01;32m'
R='\e[01;31m'
Y='\e[01;33m'
B='\e[01;34m'
V='\e[01;35m'
Bl='\e[01;30m'
C='\e[01;36m'
W='\e[01;37m'
BGBL='\e[1;30;47m'
N='\e[0m'
# shellcheck disable=SC2154
if test -n "${ANDROID_SOCKET_adbd}"; then
    G=''
    R=''
    Y=''
    B=''
    V=''
    Bl=''
    C=''
    W=''
    N=''
    BGBL=''
fi
div="${Bl}$(printf '%*s' 50 '' | tr " " "=")${N}"
do_banner() {
    clear
    echo -e " "
    echo -e "${B}▒█▀▀▀ █▀▀█ █▀▀▄ ▀▀█▀▀ ${N}"
    echo -e "${B}▒█▀▀▀ █░░█ █░░█ ░░█░░ ${N}"
    echo -e "${B}▒█░░░ ▀▀▀▀ ▀░░▀ ░░▀░░ ${N}"
    echo -e " "
    echo -e "${B}▒█▀▄▀█ █▀▀█ █▀▀▄ █▀▀█ █▀▀▀ █▀▀ █▀▀█ ${N}"
    echo -e "${B}▒█▒█▒█ █▄▄█ █░░█ █▄▄█ █░▀█ █▀▀ █▄▄▀ ${N}"
    echo -e "${B}▒█░░▒█ ▀░░▀ ▀░░▀ ▀░░▀ ▀▀▀▀ ▀▀▀ ▀░▀▀${N}"
    echo -e "An Androidacy Project"
    echo -e "For more, visit androidacy.com"
    sleep 1
}
do_banner
echo -e "$div"
echo -e "${G}Loading...${N}"
detect_ext_data() {
    if touch /sdcard/.rw && rm /sdcard/.rw; then
        export EXT_DATA="/sdcard/FontManager"
    elif touch /storage/emulated/0/.rw && rm /storage/emulated/0/.rw; then
        export EXT_DATA="/storage/emulated/0/FontManager"
    elif touch /data/media/0/.rw && rm /data/media/0/.rw; then
        export EXT_DATA="/data/media/0/FontManager"
    else
        EXT_DATA='/storage/emulated/0/FontManager'
        echo -e "⚠ Possible internal storage access issues! Please make sure data is mounted and decrypted."
        echo -e "⚠ Trying to proceed anyway "
    fi
}
detect_ext_data
if test ! -d "$EXT_DATA"; then
    mkdir -p "$EXT_DATA" >/dev/null
fi
if ! touch "EXT_DATA"/.rw && rm -fr "EXT_DATA"/.rw; then
    if ! rm -fr "$EXT_DATA" && mktouch "EXT_DATA"/.rw && rm -fr "EXT_DATA"/.rw; then
        echo -e "⚠ Cannot access internal storage!"
        it_failed
    fi
fi
mkdir -p "$EXT_DATA"/logs >/dev/null
mkdir -p "$EXT_DATA"/lists >/dev/null
MODDIR="/data/adb/modules/fontrevival"
it_failed() {
    set +euxo pipefail
    if "$1" -ne "0"; then
        echo -e "${R}============= ⓧ ERROR ⓧ =============${N}"
        echo -e "${R}Something bad happened and the script has encountered an issue${N}"
        echo -e "${R}Make sure you're following instructions and try again!${N}"
        echo -e "${R}============= ⓧ ERROR ⓧ =============${N}"
        echo -e "Exiting the script now!"
    fi
    exit "$1"
}
exec 3>&2 2>"$EXT_DATA"/logs/script.log
set -x 2
set -euo pipefail
trap 'it_failed $?' EXIT
clear
no_i() {
    do_banner
    echo -e "${R}No internet access!${N}"
    echo -e "${R}For now this module requires internet access${N}"
    echo -e "${R}Exiting${N}"
    sleep 3
    it_failed $?
}
e_spinner() {
    PID=$!
    h=0
    anim='-\|/'
    while [ -d /proc/$PID ]; do
        h=$(((h + 1) % 4))
        sleep 0.05
        # shellcheck disable=SC2145,SC2059
        printf "\r${@} [${anim:$h:1}]"
    done
}
do_quit() {
    clear
    do_banner
    echo -e "${G}Thanks for using Font Manager${N}"
    echo -e "${G}Goodbye${N}"
    sleep 2
    exit 0
}
if ! $NR; then
    echo -e "${R}Do not call this script directly! Instead call just 'manage_fonts'${N}"
    it_failed $?
fi
test_connection() {
    (ping -q -c 2 -W 2 androidacy.com >/dev/null 2>&1) && return 0 || return 1
}
font_select() {
    clear
    do_banner
    sleep 0.5
    echo -e "${G}Fonts selected.${N}"
    sleep 0.5
    echo -e "${G}Please type the name of the font you would like to apply from this list:${N}"
    echo -e "$div"
    sleep 1.5
    farr="$(cat "$MODDIR"/lists/fonts-list.txt)"
    printf "%-20s | %-20s | %-20s\n " "$farr"
    sleep 1
    echo -e "$div"
    echo -e "${G}Your choice${N}"
    echo -e "${G}x to go to main menu or q to quit:${N}"
    echo -e "$div"
    read -r a
    if test "$a" == "q"; then
        do_quit
    elif test "$a" == "x"; then
        do_banner
        echo -e "${Y}Going to main menu ${N}"
        sleep 1
        menu_set
    fi
    if ! grep -i "^$a$" "$MODDIR"/lists/fonts-list.txt >/dev/null; then
        no_i
    fi
    test_connection &
    e_spinner "${Y}Checking for internet access ${N}"
    if test $? -ne 0; then
        do_banner
        echo -e "${R}No internet access!${N}"
        echo -e "${R}For now this module requires internet access${N}"
        echo -e "${R}Exiting${N}"
        sleep 3
        it_failed $?
    else
        do_banner
        curl -kL https://dl.androidacy.com/downloads/fontifier-files/fonts/"$a".zip >"$EXT_DATA"/"$a".zip && sleep 2 &
        e_spinner "${G}Downloading $a font ${N}"
        sleep 2
        unzip "$EXT_DATA"/"$a".zip -d "$MODDIR/system/fonts" >/dev/null && sleep 2 &
        e_spinner "${G}Installing $a font ${N}"
        echo -e " "
        echo -e "${G}Install success!${N}"
        sleep 1.5
    fi
    menu_set
}
emoji_select() {
    clear
    do_banner
    sleep 0.5
    echo -e "${G}Emojis selected.${N}"
    sleep 0.5
    echo -e "${G}Please type the name of the emoji you would like to apply from this list:${N}"
    echo -e "$div"
    sleep 1.5
    earr="$(cat "$MODDIR"/lists/emojis-list.txt)"
    printf "%-20s | %-20s | %-20s\n " "$earr"
    sleep 1
    echo -e "$div"
    echo -e "${G}Your choice${N}"
    echo -e "${G}x to go to main menu or q to quit:${N}"
    echo -e "$div"
    read -r a
    if test "$a" == "q"; then
        do_quit
    elif test "$a" == "x"; then
        do_banner
        echo -e "${G}Going to main menu ${N}"
        sleep 1
        menu_set
    fi
    if ! grep -i "^$a$" "$MODDIR"/lists/emojis-list.txt >/dev/null; then
        clear
        do_banner
        echo -e "$div"
        echo -e "${R}ERROR: INVALID SELECTION${N}"
        sleep 0.5
        echo -e "${Y}Please try again${N}"
        sleep 3
        emoji_select
    fi
    test_connection &
    e_spinner "${Y}Checking for internet access ${N}"
    if test $? -ne 0; then
        no_i
    else
        do_banner
        sleep 0.2
        curl -kL https://dl.androidacy.com/downloads/fontifier-files/emojis/"$a".zip >"$EXT_DATA"/"$a".zip && sleep 2 &
        e_spinner "${G}Downloading $a emoji ${N}"
        unzip "$EXT_DATA"/"$a".zip -d "$MODDIR/system/fonts" >/dev/null && sleep 2 &
        e_spinner "${G}Installing $a emoji ${N}"
        echo -e " "
        echo -e "${G}Install success!${N}"
        sleep 1.5
    fi
    menu_set
}
update_lists() {
    do_banner
    echo -e "$div"
    test_connection &
    e_spinner "${Y}Checking for internet access ${N}"
    if test $? -ne 0; then
        no_i
    else
        mkdir -p "$MODDIR"/lists
        dl_l() {
            curl -kL https://dl.androidacy.com/downloads/fontifier-files/lists/fonts-list.txt >"$MODDIR"/lists/fonts-list.txt
            curl -kL https://dl.androidacy.com/downloads/fontifier-files/lists/emojis-list.txt >"$MODDIR"/lists/emojis-list.txt
            sed -i s/[.]zip//gi "$MODDIR"/lists/*
            cp "$MODDIR"/lists/* "$EXT_DATA"/lists
            sleep 2
        }
        dl_l &
        e_spinner "${G}Downloading fresh lists ${N}"
        sleep 1
        echo -e " "
        echo -e "${Y}Lists updated! Returning to menu${N}"
        sleep 1
        clear
        menu_set
    fi
}
get_id() {
    sed -n 's/^name=//p' "${1}"
}
detect_others() {
    for i in /data/adb/modules/*/*; do
        if test "$i" != "*fontrevival" && test ! -f "$i"/disable && test -d "$i"/system/fonts; then
            NAME=$(get_id "$i"/module.prop)
            echo -e "${R}⚠ ${N}"
            echo -e "${R}⚠ Module editing fonts detected${N}"
            echo -e "${R}⚠ Module - $NAME${N}"
            echo -e "${R}⚠ Please remove said module and retry${N}"
            sleep 4
            it_failed
        fi
    done
}
reboot() {
    do_banner
    echo -e "$div"
    echo -e "${R}Press Ctrl-C to cancel reboot${N}"
    sleep 5 &
    e_spinner "${R} Rebooting in five seconds.${N}"
    setprop sys.powerctl reboot
}
menu_set() {
    while :; do
        detect_others
        do_banner
        echo -e "$div"
        echo -e "${G}MAIN MENU:${N}"
        echo -e "${G}1. Change your font${N}"
        echo -e "${G}2. Change your emoji${N}"
        echo -e "${G}3. Update font and emoji lists${N}"
        echo -e "${G}4. Reboot to apply changes${N}"
        echo -e "${G}5. Quit${N}"
        echo -e "$div"
        echo -e "${G}Your choice:${N}"
        read -r a
        case $a in
        1*) font_select ;;
        2*) emoji_select ;;
        3*) update_lists ;;
        4*) reboot ;;
        5*) do_quit ;;
        *) echo -e "${R}Invalid option, please try again${N}" && sleep 2 && menu_set ;;
        esac
    done
}
menu_set
