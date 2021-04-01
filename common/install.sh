# shellcheck shell=ash
# shellcheck disable=SC2169
do_banner() {
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
	sleep 2
}
do_banner
ui_print "ⓘ Welcome to Font Manager!"
ui_print "ⓘ Setting up enviroment..."
test_connection() {
	ui_print "ⓘ Testing internet connectivity"
	(ping -4 -q -c 1 -W 2 www.androidacy.com >/dev/null 2>&1) && return 0 || return 1
}
get_lists() {
	test_connection
	if test $? -ne 0; then
		ui_print "ⓘ No internet access!"
		ui_print "ⓘ This module requires internet access."
		ui_print "ⓘ There is no current plans for making it work offline, as it requires certain online files."
		ui_print "ⓘ Aborting"
		abort
	else
		ui_print "ⓘ Excellent, you have internet."
		ui_print "ⓘ Downlading extra files..."
		mkdir -p "$MODPATH"/lists
		mkdir -p "$EXT_DATA"/lists
		mkdir -p "$EXT_DATA"/font
		mkdir -p "$EXT_DATA"/emoji
		curl -kL https://dl.androidacy.com/downloads/fontifier-files/lists/fonts-list.txt >"$MODPATH"/lists/fonts-list.txt
		curl -kL https://dl.androidacy.com/downloads/fontifier-files/lists/emojis-list.txt >"$MODPATH"/lists/emojis-list.txt
		sed -i s/[.]zip//gi "$MODPATH"/lists/*
		mkdir -p "$MODPATH"/"$(find /*/etc | grep fonts.xml | sed 's/fonts[.]xml//')"
		cp "$MODPATH"/lists/* "$EXT_DATA"/lists
		curl -kL https://dl.androidacy.com/downloads/fontifier-files/xml/fonts.xml >"$MODPATH"/"$(find /*/etc | grep fonts.xml)"
	fi
}
copy_lists() {
	cp -rf "$MODPATH"/lists/fonts-list.txt "$EXT_DATA"/lists/fonts-list.txt
	cp -rf "$MODPATH"/lists/emojis-list.txt "$EXT_DATA"/lists/emojis-list.txt
}
setup_script() {
	chmod 755 -R "$MODPATH"/system/bin/
	mkdir "$MODPATH"/system/fonts
}
extra_cleanup() {
	rm -rf "$MODPATH"/*.md
	rm -rf "$MODPATH"/LICENSE
}
get_lists
copy_lists
setup_script
extra_cleanup
{
	echo "Here's some useful links:"
	echo " "
	echo "Website: https://www.androidacy.com"
	echo "Donate: https://www.androidacy.com/donate/"
	echo "Support and contact: https://www.anroidacy.com/contact/"
} >"$EXT_DATA"/README.txt
ui_print "⚠ Please make sure not to have any other font changing modules installed ⚠"
ui_print "⚠ Please remove any such module, as it conflicts with this module ⚠"
