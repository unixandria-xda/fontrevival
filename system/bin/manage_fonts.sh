#!/data/adb/modules/fontrevival/tools/busybox ash
# shellcheck shell=ash
do_banner() {
    cat <<"EOF"
███████  ██████  ███    ██ ████████                           
██      ██    ██ ████   ██    ██                              
█████   ██    ██ ██ ██  ██    ██                              
██      ██    ██ ██  ██ ██    ██                              
██       ██████  ██   ████    ██                              
                                                              
███    ███  █████  ███    ██  █████   ██████  ███████ ██████  
████  ████ ██   ██ ████   ██ ██   ██ ██       ██      ██   ██ 
██ ████ ██ ███████ ██ ██  ██ ███████ ██   ███ █████   ██████  
██  ██  ██ ██   ██ ██  ██ ██ ██   ██ ██    ██ ██      ██   ██ 
██      ██ ██   ██ ██   ████ ██   ██  ██████  ███████ ██   ██ 
EOF
    printf '\n%s\n' "An Androidacy Project"
    printf '\n%s' "For more, visit androidacy.com"
    sleep 2
}
do_banner
if test "$(getenforce)" == "Enforcing" || test "$(getenforce)" == "enforcing"; then
    setenforce 0
    IS_ENFORCE=true
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
        ui_print "⚠ Possible internal storage access issues! Please make sure data is mounted and decrypted."
        ui_print "⚠ Trying to proceed anyway..."
    fi
}

detect_ext_data
if test ! -d "$EXT_DATA"; then
    mkdir "$EXT_DATA"
fi
if ! mktouch "EXT_DATA"/.rw && rm -fr "EXT_DATA"/.rw; then
    if ! rm -fr "$EXT_DATA" && mktouch "EXT_DATA"/.rw && rm -fr "EXT_DATA"/.rw; then
        ui_print "⚠ Cannot access internal storage!"
        it_failed
    fi
fi
MODDIR="/data/adb/modules/fontrevival"
exxit() {
    set +euxo pipefail
    [ "$1" -ne 0 ] && exxit $? "$2"
    printf '\n%s' "============= ⓧ ERROR ⓧ ============="
    printf '\n%s' "Something bad happened and the script has encountered an issue"
    printf '\n%s' "Please report this bug with logs to the developer!"
    printf '\n%s' "============= ⓧ ERROR ⓧ ============="
    printf '\n%s\n' "Exiting the script now!"
    exit "$1"
}
exec 3>&2 2>"$EXT_DATA"/logs/script.log
set -x 2
set -euo pipefail
trap 'exxit $?' EXIT
clear
do_quit() {
    clear
    do_banner
    printf '\n%s\n' "Thanks for using Font Manager"
    printf '\n%s\n' "Goodbye"
    sleep 2
    if $IS_ENFORCE; then
        setenforce 1
    fi
    exit 0
}
if ! $NATIVE_RUN; then
    printf '\n%s\n' "Do not call this script directly! Instead call just 'manage_fonts'"
    exxit $?
fi
test_connection() {
    printf '\n%s\n' "Checking for internet access..."
    (ping -q -c 2 -W 2 androidacy.com >/dev/null 2>&1) && return 0 || return 1
}
dl() {
    "$MODDIR"/tools/aria2c -s 16 -x 16 --async-dns --check-certificate=false --ca-certificate="$MODDIR"/ca-certificates.crt --quiet "$@"
}
font_select() {
    clear
    do_banner
    sleep 0.5
    printf '\n%s\n' "Fonts selected."
    sleep 0.5
    printf '\n%s\n' "Please type the name of the font you would like to apply from this list:"
    printf '\n%s\n' "======================================================="
    printf '\n%s\n' "======================================================="
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
    printf '\n%s' "======================================================="
    printf '\n%s' "Your choice"
    printf '\n%s' "x or go to main menu or q to quit:"
    printf '\n%s\n' "======================================================="
    read -r a
    if "$a" == "q"; then
        do_quit
    elif "$a" == "x"; then
        do_banner
        printf '\n%s\n' "Going to main menu..."
        sleep 1
        menu_set
    fi
    test_connection
    if test $? -ne 0; then
        printf '\n%s\n' "- No internet access!"
        printf '\n%s\n' "- For now this module requires internet access"
        printf '\n%s\n' "- Exiting"
        exxit $?
    else
        dl https://dl.androidacy.com/downloads/fontifier-files/fonts/"$a".zip -d "$EXT_DATA"/
        if test $? -ne 0; then
            clear
            printf '\n%s\n' "ERROR: INVALID SELECTION"
            sleep 0.5
            printf '\n%s\n' "Please try again"
            sleep 5
            font_select
        else
            clear
            sleep 0.2
            do_banner
            printf '\n%s\n' "Now installing the font..."
            sleep 2
            unzip "$EXT_DATA"/"$a".zip -d "$MODDIR/system/fonts"
            printf '\n%s\n' "Install success!"
            sleep 1.5
        fi
    fi
    menu_set
}
emoji_select() {
    clear
    do_banner
    sleep 0.5
    printf '\n%s\n' "Emojis selected."
    sleep 0.5
    printf '\n%s\n' "======================================================="
    printf '\n%s\n' "======================================================="
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
    printf '\n%s' "======================================================="
    printf '\n%s' "Your choice"
    printf '\n%s' "x to go to main menu or q to quit:"
    printf '\n%s\n' "======================================================="
    read -r a
    if "$a" == "q"; then
        do_quit
    elif "$a" == "x"; then
        do_banner
        printf '\n%s\n' "Going to main menu..."
        sleep 1
        menu_set
    fi
    test_connection
    if test $? -ne 0; then
        printf '\n%s\n' "- No internet access!"
        printf '\n%s\n' "- For now this module requires internet access"
        printf '\n%s\n' "- Exiting"
        exxit $?
    else
        dl https://dl.androidacy.com/downloads/fontifier-files/emojis/"$a".zip -d "$EXT_DATA"/
        if test $? -ne 0; then
            clear
            printf '\n%s\n' "ERROR: INVALID SELECTION"
            sleep 0.5
            printf '\n%s\n' "Please try again"
            sleep 5
            emoji_select
        else
            clear
            do_banner
            sleep 0.2
            printf '\n%s\n' "Now installing the emoji..."
            sleep 2
            unzip "$EXT_DATA"/"$a".zip -d "$MODDIR/system/fonts"
            printf '\n%s\n' "Install success!"
            sleep 1.5

        fi
    fi
    menu_set
}
update_lists() {
    do_banner
    test_connection
    if test $? -ne 0; then
        printf '\n%s\n' "- No internet access!"
        printf '\n%s\n' "- For now this module requires internet access"
        printf '\n%s\n' "- Exiting"
        exxit $?
    else
        printf '\n%s\n' "- Excellent, you have internet."
        printf '\n%s\n' "- Downlading extra lists..."
        mkdir -p "$MODDIR"/lists
        dl https://dl.androidacy.com/downloads/fontifier-files/lists/fonts-list.txt -d "$MODDIR"/lists/
        dl https://dl.androidacy.com/downloads/fontifier-files/lists/emojis-list.txt -d "$MODDIR"/lists/
        cp "$MODDIR"/lists/* "$EXT_DATA"/lists
        sleep 0.5
        printf '\n%s\n' "Lists updated! Returning to menu"
        sleep 1
        clear
        menu_set
    fi
}
detect_others() {
    clear
    do_banner
    printf '\n%s' "⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  "
    printf '\n%s' "⚠   Please make sure not to have any other font changing modules installed ⚠  "
    printf '\n%s' "⚠       Please remove any such module, as it conflicts with Font Manager      ⚠  "
    printf '\n%s\n' "⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠  ⚠   ⚠  "
    sleep 3
    clear
}
menu_set() {
    while :; do
        detect_others
        do_banner
        printf '\n%s' "======================================================="
        printf '\n%s' "====================== MAIN MENU ======================"
        printf '\n%s' "1. Change your font"
        printf '\n%s' "2. Change your emoji"
        printf '\n%s' "3. Update font and emoji lists"
        printf '\n%s' "4. Quit"
        printf '\n%s\n' "======================================================="
        printf '\n%s' "Your choice:"
        read -r a
        case $a in
        1*) font_select ;;
        2*) emoji_select ;;
        3*) update_lists ;;
        4*) do_quit ;;
        *) printf '\n%s\n' "Invalid option, please try again..." && sleep 3 && menu_set ;;
        esac
    done
}
menu_set
