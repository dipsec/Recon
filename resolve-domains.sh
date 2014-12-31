#!/bin/bash

# Description
# -----------
# Resolve domain names


if [[ -z $1 ]] || [[ $1 == --help ]]; then
	echo Usage: resolve-domains.sh [DOMAINS FILE NAME]
	echo;
	exit
fi

# Check the given file is exist #
if [ ! -f $1 ]; then
        echo "Filename \"$1\" doesn't exist"
        exit
fi

while read -u 10 f; do
   if [[ $f == http* ]] || [[ -z $f ]]; then
        echo File Format is Incorrect!
        echo Filename format: DOMAIN.COM
        echo;
        exit
   fi
done 10< $1

while read -u 10 domain; do
	echo $domain
	ping -c 1 $domain |cut -d' ' -f2,3 | grep -v statistics | grep -v packets >> $1.resolved.tmp
done 10< $1

grep -v ping $1.resolved.tmp |sort -u > $1.resolved2.tmp
sed '/^$/d' $1.resolved2.tmp > $1.resolved.txt
rm *.tmp
