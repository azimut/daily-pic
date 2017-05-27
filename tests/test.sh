#!/bin/bash
source do.sh

echo '|Source|Status|'
echo '|:--|--:|'

for s in $(declare -F | grep http.get.url | cut -f3 -d' '); do
    if $s  2>/dev/null | grep http &>/dev/null ; then
        printf '|%s|%s|\n' "$s" "Up"
    else
        printf '|%s|%s|\n' "$s" "Down"
    fi
done
