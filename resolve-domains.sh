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

dos2unix -n $1 ~/$folder/$client/domains.tmp
file=~/$folder/$client/domains.tmp

while read -u 10 domain; do
	echo $domain
	ping -c 1 $domain |cut -d' ' -f2,3 | grep -v statistics | grep -v packets >> $1.resolved.tmp
done 10< $file

grep -v ping $file.resolved.tmp |sort -u > $file.resolved2.tmp
sed '/^$/d' $file.resolved2.tmp > $file.resolved.txt
rm *.tmp
