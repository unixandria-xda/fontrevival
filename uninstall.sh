# shellcheck shell=ash
# Don't modify anything after this
if [ -f "$INFO" ]; then
  while read -r LINE; do
    if [ "$(echo -n "$LINE" | tail -c 1)" = "~" ]; then
      continue
    elif [ -f "$LINE~" ]; then
      mv -f "$LINE~" "$LINE"
    else
      rm -f "$LINE"
      while true; do
        LINE=$(dirname "$LINE")
        # shellcheck disable=SC2015
        [ "$(ls -A "$LINE" 2>/dev/null)" ] && break 1 || rm -rf "$LINE"
      done
    fi
  done <"$INFO"
  rm -f "$INFO"
fi
setenforce 0
rm -rf /sdcard/Fontifier
setenforce 1
