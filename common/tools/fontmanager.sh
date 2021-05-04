#!/bin/bash
# shellcheck shell=bash
# shellcheck disable=SC2034,SC2183,SC2154,SC1091
clear
echo "Loading..."
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
if ! touch "$EXT_DATA"/.rw && rm -fr "$EXT_DATA"/.rw; then
    if ! rm -fr "$EXT_DATA" && touch "$EXT_DATA"/.rw && rm -fr "$EXT_DATA"/.rw; then
        echo -e "⚠ Cannot access internal storage!"
        it_failed
    fi
fi
mkdir -p "$EXT_DATA"/logs >/dev/null
mkdir -p "$EXT_DATA"/lists >/dev/null
MODDIR="/data/adb/modules/fontrevival"
exec > >(tee -ia "$EXT_DATA"/logs/script.log)
exec 2> >(tee -ia "$EXT_DATA"/logs/script.log >&2)
exec 19>"$EXT_DATA"/logs/script.log
export BASH_XTRACEFD="19"
set -x
set -o functrace
shopt -s checkwinsize
shopt -s expand_aliases
. /data/adb/modules/fontrevival/tools/utils
# shellcheck disable=SC2154
if test -n "${ANDROID_SOCKET_adbd}"; then
    echo -e "ⓧ Please run this in a terminal emulator on device! ⓧ"
    exit 1
fi
if test "$(id -u)" -ne 0; then
    echo -e "${R}Please run this script as root!${N}"
    exit 1
fi
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
    echo -e "$div"
    sleep 1
}
if ! $NR; then
    echo -e "${R}Do not call this script directly! Instead call just 'manage_fonts'${N}"
    it_failed
fi
TRY_COUNT=1
no_i() {
    do_banner
    echo -e "${R}No internet access!${N}"
    echo -e "${R}For now this module requires internet access${N}"
    echo -e "${R}Exiting${N}"
    sleep 3
    it_failed
}
do_quit() {
    clear
    do_banner
    echo -e "${G}Thanks for using Font Manager${N}"
    echo -e "${G}Goodbye${N}"
    sleep 2
    exit 0
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
        echo -e "${R}ERROR: INVALID SELECTION${N}"
        sleep 0.5
        echo -e "${Y}Please try again${N}"
        sleep 3
        font _select
    fi
    do_banner
    test_connection &
    e_spinner "${Y}Checking for internet access ${N}"
    if test $? -ne 0; then
        no_i
    else
        dl "&s=fonts&w=&a=$a&ft=zip" "$EXT_DATA/font/$a.zip" "download" && sleep 1 &
        e_spinner "${G}Downloading $a font ${N}"
        sleep 2
        in_f() {
            unzip "$EXT_DATA"/font/"$a".zip -d "$MODDIR/system/fonts" &>/dev/null
            set_perm_recursive 644 root root 0 "$MODDIR"/system/fonts/*
            if test -d /product/fonts; then
                mkdir -p "$MODDIR"/system/product/fonts
                cp "$MODDIR"/system/fonts/* "$MODDIR"/system/product/fonts/
                set_perm_recursive 644 root root 0 "$MODDIR"/system/product/fonts/*
            fi
            if test -d /system_ext/fonts; then
                mkdir -p "$MODDIR"/system/system_ext/fonts
                cp "$MODDIR"/system/fonts/* "$MODDIR"/system/system_ext/fonts/
                set_perm_recursive 644 root root 0 "$MODDIR"/system/system_ext/fonts/*
            fi
            echo "$a" >"$MODDIR"/cfont
            sleep 1
        }
        in_f &
        e_spinner "${G}Installing $a font ${N}"
        echo -e " "
        echo -e "${G}Install success! Returning to menu${N}"
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
        echo -e "${R}ERROR: INVALID SELECTION${N}"
        sleep 0.5
        echo -e "${Y}Please try again${N}"
        sleep 3
        emoji_select
    fi
    do_banner
    test_connection &
    e_spinner "${Y}Checking for internet access ${N}"
    if test $? -ne 0; then
        no_i
    else
        sleep 0.2
        dl "&s=emojis&w=&a=$a&ft=zip" "$EXT_DATA/emoji/$a.zip" "download" && sleep 1 &
        e_spinner "${G}Downloading $a emoji ${N}"
        unzip "$EXT_DATA"/emoji/"$a".zip -d "$MODDIR/system/fonts" &>/dev/null && set_perm_recursive 644 root root 0 "$MODDIR"/system/fonts/* && echo "$a" >"$MODDIR"/cemoji && sleep 2 &
        e_spinner "${G}Installing $a emoji ${N}"
        echo -e " "
        echo -e "${G}Install success! Returning to menu${N}"
        sleep 1.65
    fi
    menu_set
}
update_lists() {
    do_banner
    test_connection &
    e_spinner "${Y}Checking for internet access ${N}"
    if test $? -ne 0; then
        no_i
    else
        mkdir -p "$MODDIR"/lists
        dl_l() {
            dl "&s=lists&w=&a=fonts-list&ft=txt" "$MODDIR"/lists/fonts-list.txt "download"
            dl "&s=lists&w=&a=emojis-list&ft=txt" "$MODDIR"/lists/emojis-list.txt "download"
            sed -i s/[.]zip//gi "$MODDIR"/lists/*
            cp "$MODDIR"/lists/* "$EXT_DATA"/lists
            sleep 1.75
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
reboot_fn() {
    do_banner
    echo -en "${R}Are you sure you want to reboot? [y/N] ${N}"
    read -r a
    if test "$a" == "y"; then
        /system/bin/svc power reboot || /system/bin/reboot || setprop sys.powerctl reboot
    else
        echo -e "${Y}Reboot cancelled${N}"
        sleep 2
        menu_set
    fi
}
rever_st() {
    do_banner
    r_s() {
        rm -fr "$MODDIR"/system/fonts/*
        rm -fr "$MODDIR"/system/*/fonts/*
        rm -fr "$MODDIR"/c*
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
        for i in font emoji; do
            if test ! -f $MODDIR/c$i; then
                echo "stock" >$MODDIR/c$i
            fi
        done
        echo -e "${G}Current font is $(cat $MODDIR/cfont)${N}"
        echo -e "${G}Current emoji is $(cat $MODDIR/cemoji)${N}"
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
        5*) reboot_fn ;;
        6*) do_quit ;;
        *) echo -e "${R}Invalid option, please try again${N}" && sleep 2 && menu_set ;;
        esac
    done
}
detect_others
menu_set
