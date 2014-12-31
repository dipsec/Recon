#! /bin/bash

# Description
# -----------
# Resolve IP Addresses to Domain Names


if [[ -z $1 ]] || [[ $1 == --help ]]; then
	echo Usage: reverse-iplookup.sh [IPs FILE NAME]
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
        echo Filename format: 123.456.789.1
        echo;
        exit
   fi
done 10< $1


while read -u 10 ip; do
        echo $ip
	echo $ip >> $1.reversed.txt
        dig +short -x $ip | xargs echo -n >> $1.reversed.txt
	echo " " >> $1.reversed.txt
	echo "--------------------------" >> $1.reversed.txt
done 10< $1
