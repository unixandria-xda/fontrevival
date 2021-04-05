# shellcheck shell=bash
# shellcheck disable=SC2169
# shellcheck disable=SC2034
# shellcheck disable=SC2183
# shellcheck disable=SC2145
# shellcheck disable=SC2155
# shellcheck disable=SC2059
shopt -s checkwinsize
resize
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
if test "$(id -u)" -ne 0; then
	echo -e "Please run this script as root!"
	exit 1
fi
if test -n "${ANDROID_SOCKET_adbd}"; then
    echo -e "Please run this in a terminal emulator on device!"
    exit 1
fi
COLUMNS="$(stty size | cut -d" " -f2)"
div="${Bl}$(printf '%*s' $((COLUMNS * 90 / 100)) '' | tr " " "=")${N}"
do_banner() {
    clear
    echo -e "${B}  _____              _                           ${N}"
    echo -e "${B} |  ___|___   _ __  | |_                         ${N}"
    echo -e "${B} | |_  / _ \ | '_ \ | __|                        ${N}"
    echo -e "${B} |  _|| (_) || | | || |_                         ${N}"
    echo -e "${B} |_|   \___/ |_| |_| \__|                        ${N}"
    echo -e "${B}  __  __                                         ${N}"
    echo -e "${B} |  \/  |  __ _  _ __    __ _   __ _   ___  _ __ ${N}"
    echo -e "${B} | |\/| | / _\` || '_ \  / _\` | / _\` | / _ \| '__|${N}"
    echo -e "${B} | |  | || (_| || | | || (_| || (_| ||  __/| |   ${N}"
    echo -e "${B} |_|  |_| \__,_||_| |_| \__,_| \__, | \___||_|   ${N}"
    echo -e "${B}                               |___/             ${N}"
    echo -e "${B}An Androidacy project - androidacy.com${N}"
    sleep 1
}
do_banner
echo -e "$div"
echo -e "${G}Loading...${N}"
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
if ! $NR; then
    echo -e "${R}Do not call this script directly! Instead call just 'manage_fonts'${N}"
    it_failed
fi
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
        sleep 2
    fi
}
detect_ext_data
if test ! -d "$EXT_DATA"; then
    mkdir -p "$EXT_DATA" >/dev/null
fi
if ! touch "EXT_DATA"/.rw && rm -fr "EXT_DATA"/.rw; then
    if ! rm -fr "$EXT_DATA" && touch "EXT_DATA"/.rw && rm -fr "EXT_DATA"/.rw; then
        echo -e "⚠ Cannot access internal storage!"
        it_failed
    fi
fi
mkdir -p "$EXT_DATA"/logs >/dev/null
mkdir -p "$EXT_DATA"/lists >/dev/null
MODDIR="/data/adb/modules/fontrevival"
exec 3>&2 2>"$EXT_DATA"/logs/script.log
set -x 2
set -o pipefail
trap 'it_failed' EXIT
no_i() {
    do_banner
    echo -e "${R}No internet access!${N}"
    echo -e "${R}For now this module requires internet access${N}"
    echo -e "${R}Exiting${N}"
    sleep 3
    it_failed
}
e_spinner() {
    PID=$!
    h=0
    anim='◐◓◑◒'
    while [ -d /proc/$PID ]; do
        h=$(((h + 1) % 4))
        sleep 0.02
        # shellcheck disable=SC2145,SC2059
        printf "\r${@}[${anim:$h:1}]"
    done
}
do_quit() {
    clear
    do_banner
    echo -e "$div"
    echo -e "${G}Thanks for using Font Manager${N}"
    echo -e "${G}Goodbye${N}"
    sleep 2
    exit 0
}
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
    sleep 2
    farr="$(cat "$MODDIR"/lists/fonts-list.txt)"
    # shellcheck disable=SC2086
    printf "%-20s | %-20s | %-20s\n " $farr
    sleep 1
    echo -e "$div"
    echo -e "${G}x to go to main menu or q to quit${N}"
    echo -en "${G}Please make a selection => ${N}"
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
         do_banner
        echo -e "$div"
        echo -e "${R}ERROR: INVALID SELECTION${N}"
        sleep 0.5
        echo -e "${Y}Please try again${N}"
        sleep 3
        font _select
    fi
	do_banner
	echo -e "$div"
    test_connection &
    e_spinner "${Y}Checking for internet access ${N}"
    if test $? -ne 0; then
        no_i
    else
        curl -kL https://dl.androidacy.com/downloads/fontifier-files/fonts/"$a".zip >"$EXT_DATA"/"$a".zip && sleep 1 &
        e_spinner "${G}Downloading $a font ${N}"
        sleep 2
        in_f() { 
        	unzip "$EXT_DATA"/"$a".zip -d "$MODDIR/system/fonts" >/dev/null
			if test -d /product/fonts; then
				mkdir -p "$MODDIR"/system/product/fonts
				cp "$MODDIR"/system/fonts/* "$MODDIR"/system/product/fonts/
			fi
			if test -d /system_ext/fonts; then
				mkdir -p "$MODDIR"/system/system_ext/fonts
				cp "$MODDIR"/system/fonts/* "$MODDIR"/system/system_ext/fonts/
			fi
			sleep 1
		}
		in_f &
        e_spinner "${G}Installing $a font ${N}"
        echo -e " "
        echo -e "${G}Install success!${N}"
        echo "$a" >"$MODDIR"/curr-font.txt
        sleep 2
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
    sleep 2
    earr="$(cat "$MODDIR"/lists/emojis-list.txt)"
    # shellcheck disable=SC2086
    printf "%-20s | %-20s | %-20s\n " $earr
    sleep 1
    echo -e "$div"
    echo -e "${G}x to go to main menu or q to quit${N}"
    echo -en "${G}Please make a selection => ${N}"
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
        do_banner
        echo -e "$div"
        echo -e "${R}ERROR: INVALID SELECTION${N}"
        sleep 0.5
        echo -e "${Y}Please try again${N}"
        sleep 3
        emoji_select
    fi
	do_banner
	echo -e "$div"
    test_connection &
    e_spinner "${Y}Checking for internet access ${N}"
    if test $? -ne 0; then
        no_i
    else
        sleep 0.2
        curl -kL https://dl.androidacy.com/downloads/fontifier-files/emojis/"$a".zip >"$EXT_DATA"/"$a".zip && sleep 1 &
        e_spinner "${G}Downloading $a emoji ${N}"
        unzip "$EXT_DATA"/"$a".zip -d "$MODDIR/system/fonts" >/dev/null && sleep 2 &
        e_spinner "${G}Installing $a emoji ${N}"
        echo -e " "
        echo -e "${G}Install success!${N}"
        echo "$a" >"$MODDIR"/curr-emoji.txt
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
            sleep 2.5
        }
        dl_l &
        e_spinner "${G}Downloading fresh lists ${N}"
        echo -e " "
        echo -e "${Y}Lists updated! Returning to menu${N}"
        sleep 2
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
    echo -en "${R}Are you sure you want to reboot? [y/N] ${N}"
    read -r a
	if test "$a" == "y"; then
    	setprop sys.powerctl reboot
	else
		menu_set
	fi
}
rever_st() {
    do_banner
    r_s() {
        rm -fr "$MODDIR"/system/fonts/*
        rm -fr "$MODDIR"/curr*
        sleep 2
    }
    r_s &
    e_spinner "${G}Reverting to stock fonts ${N}"
    echo -e "\n${G}Stock fonts applied! Please reboot.${N}"
    sleep 2
    menu_set
}
menu_set() {
    while :; do
        do_banner
        echo -e "$div"
        for i in curr-font curr-emoji; do
            if test ! -f $MODDIR/$i.txt; then
                echo "stock" >$MODDIR/$i.txt
            fi
        done
        echo -e "${G}Current font is $(cat $MODDIR/curr-font.txt)${N}"
        echo -e "${G}Current emoji is $(cat $MODDIR/curr-emoji.txt)${N}"
        echo -e "$div"
        echo -e "${G}Available options:${N}"
        echo -e "${G}1. Change your font${N}"
        echo -e "${G}2. Change your emoji${N}"
        echo -e "${G}3. Update font and emoji lists${N}"
        echo -e "${G}4. Revert to stock font and emoji${N}"
        echo -e "${G}5. Reboot to apply changes${N}"
        echo -e "${G}6. Quit${N}"
        echo -e "$div"
        echo -en "${G}Please make a selection => ${N}"
        read -r a
        case $a in
        1*) font_select ;;
        2*) emoji_select ;;
        3*) update_lists ;;
        4*) rever_st ;;
        5*) reboot ;;
        6*) do_quit ;;
        *) echo -e "${R}Invalid option, please try again${N}" && sleep 2 && menu_set ;;
        esac
    done
}
detect_others
menu_set
