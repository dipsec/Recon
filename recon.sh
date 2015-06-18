#! /bin/bash

# recon - Automates Basic Recon Checks
# Copyright (C) 2014 Joseph Barcia - joseph@barcia.me
# https://github.com/jbarcia
#
# License
# -------
# This tool may be used for legal purposes only.  Users take full responsibility
# for any actions performed using this tool.  The author accepts no liability
# for damage caused by this tool.  If you do not accept these condition then
# you are prohibited from using this tool.
#
# In all other respects the GPL version 2 applies:
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# You are encouraged to send comments, improvements or suggestions to
# me at joseph@barcia.me
#
#
# Description
# -----------
# Automates basic web check tools including nikto, cewl, nmap vhosts nse,
# and website scraping with wget.
#
# It is intended to be run by security auditors and pentetration testers
# against systems they have been engaged to assess.
#
# Ensure that you have the appropriate legal permission before running it
# someone else's system.
#
#
# Changelog
# ---------
# version=1.0
# Added:
# harvester email. virtual hosts, and hosts check
# wget robots.txt
# website scraping (doc, pdf, bak)
# cewl website scrape
#
# TO DO
# ---------
# Add WHOIS checks
# add modules for specific checks

if [[ $# -lt 2 ]] || [[ $1 == --help ]]; then
	echo Usage: recon.sh [DOMAINS FILE NAME] [CLIENT NAME]
	echo;
	exit
fi


domains=$1
client=$2
REPLY=n

# Check the given file is exist #
if [ ! -f $domains ]
then
        echo "Filename \"$domains\" doesn't exist"
        exit
fi

while read -u 10 f; do
   if [[ $f == http* ]] || [[ -z $f ]]; then
        echo File Format is Incorrect!
        echo Filename format: DOMAIN.COM
        echo;
        exit
   fi
done 10< $domains


##################### Replace Folder Location ######################
folder=Projects
path=~/$folder/$client/Recon
##################### Replace Script Location ######################
scriptloc=/root/scripts/Recon
wordlists=/root/scripts/SecLists

echo;
echo Save files to: $path
echo Call scripts from: $scriptloc
echo DNS Wordlist location: $wordlists
read -p "Do any of these variables need to be updated? [Y/N]    "
if [ "$REPLY" == "y" -o "$REPLY" == "Y" ]; then
	echo;
	exit
else
    echo Continuing...
fi

mkdir -p ~/$folder
mkdir -p ~/$folder/$client
mkdir -p $path
mkdir -p $path/WHOIS
mkdir -p $path/DNS
mkdir -p $path/harvester
mkdir -p $path/robots
mkdir -p $path/cewl
mkdir -p $path/web_docs

dos2unix -n $domains ~/$folder/$client/domains.tmp
domains=~/$folder/$client/domains.tmp

while read -u 10 domain; do
	echo $domain

mkdir -p $path/DNS/$domain
mkdir -p $path/harvester/$domain
mkdir -p $path/cewl/$domain
mkdir -p $path/web_docs/$domain

	theharvester -d $domain -b all -vn -f $path/harvester/$domain/$domain.harvester.html 2>&1 |tee $path/harvester/$domain/$domain.harvester.txt
	sed -n '/Emails found:/,/Hosts found/p' $path/harvester/$domain/$domain.harvester.txt |grep -v Hosts |grep -v Emails|grep -v '-' > $path/harvester/$domain/$domain.emails.txt
	sed -n '/Hosts found in search engines/,/active queries/p' $path/harvester/$domain/$domain.harvester.txt |grep -v Hosts |grep -v queries|grep -v '-' |sed -e 's/:/,/g' > $path/harvester/$domain/$domain.SearchEngines.txt
	sed -n '/Hosts found after reverse lookup/,/Virtual hosts/p' $path/harvester/$domain/$domain.harvester.txt |grep -v Hosts |grep -v hosts|grep -v '-' |sed -e 's/:/,/g' > $path/harvester/$domain/$domain.ReverseLookup.txt
	sed -n '/Virtual hosts/,$p' $path/harvester/$domain/$domain.harvester.txt |grep -v Hosts |grep -v hosts|grep -v '=' > $path/harvester/$domain/$domain.VirtualHosts.txt
	wget -t 5 -e robots=off $domain/robots.txt -O $path/robots/$domain.robots.txt
	cewl --count --verbose -m 8 -o --write $path/cewl/$domain/$domain.passwordscrape.txt --meta --meta_file $path/cewl/$domain/$domain.meta.txt --email --email_file $path/cewl/$domain/$domain.emails.txt $domain
	wget -t 5 -e robots=off --wait 1 -nd -r -A pdf,doc,docx,xls,xlsx,old,bac,bak,bc -P $path/web_docs/$domain $domain
	dig $domain NS > $path/DNS/$domain.nameserver.txt
	dig $domain MX > $path/DNS/$domain.mailserver.txt
	dig $domain A > $path/DNS/$domain.address.txt
	dnsenum --threads 20 -f $wordlists/DNS/deepmagic.com_top50kprefixes.txt -u a -r -p 15 -s 15 --subfile $path/DNS/$domain/$domain.subdomains.txt -o $path/DNS/$domain/$domain.dnsenum.xml $domain 2>&1 |tee $path/DNS/$domain/$domain.dnsenum.txt
	whois $domain > $path/WHOIS/Whois-$domain.txt
done 10<$domains

perl $scriptloc/whois.pl -i $domains -o $path/WHOIS/Whois-$client.csv
perl $scriptloc/Whois_LockandExpiration.pl -i $domains -o $path/WHOIS/WhoisLockAndExpiration-$client.csv
perl $scriptloc/DNSDigger.pl -d $domains > $path/DNS/DNSDigger-$client.csv
$scriptloc/recon-ng_script.sh $domains $client $folder $scriptloc
