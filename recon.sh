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

if [[ -z $1 ]]; then
	echo Usage: recon.sh [DOMAINS FILE NAME] [CLIENT NAME]
	echo;
	exit
fi

if [[ -z $2 ]]; then
	echo Usage: recon.sh [DOMAINS FILE NAME] [CLIENT NAME]
	echo;
	exit
fi

domains=$1
client=$2
##################### Replace Folder Location ######################
folder=in-epa-nov17
path=~/$folder/$client
##################### Replace Script Location ######################
scriptloc=/mnt/hgfs/isadmintools/GitHub/Recon
wordlists=/root/scripts/SecLists

mkdir -p /root/$folder
mkdir -p $path
mkdir -p $path/Identification
mkdir -p $path/Identification/WHOIS
mkdir -p $path/Identification/DNS
mkdir -p $path/Identification/harvester
mkdir -p $path/Assessment
mkdir -p $path/Assessment/Web
mkdir -p $path/Assessment/Web/robots
mkdir -p $path/Assessment/Web/cewl
mkdir -p $path/Assessment/Web/web_docs

while read -u 10 domain; do
	echo $domain

	theharvester -d $domain -b all -vn -f $path/Identification/harvester/$domain.harvester.xml 2>&1 |tee $path/Identification/harvester/$domain.harvester.txt
	sed -n '/Emails found:/,/Hosts found/p' $path/Identification/harvester/$domain.harvester.txt |grep -v Hosts |grep -v Emails|grep -v '-' > $path/Identification/harvester/$domain.emails.txt
	sed -n '/Hosts found in search engines/,/active queries/p' $path/Identification/harvester/$domain.harvester.txt |grep -v Hosts |grep -v queries|grep -v '-' |sed -e 's/:/,/g' > $path/Identification/harvester/$domain.SearchEngines.txt
	sed -n '/Hosts found after reverse lookup/,/Virtual hosts/p' $path/Identification/harvester/$domain.harvester.txt |grep -v Hosts |grep -v hosts|grep -v '-' |sed -e 's/:/,/g' > $path/Identification/harvester/$domain.ReverseLookup.txt
	sed -n '/Virtual hosts/,$p' $path/Identification/harvester/$domain.harvester.txt |grep -v Hosts |grep -v hosts|grep -v '=' > $path/Identification/harvester/$domain.VirtualHosts.txt
	wget -t 5 -e robots=off $domain/robots.txt -O $path/Assessment/Web/robots/$domain.robots.txt
	cewl --count --verbose -m 8 -o --write $path/Assessment/Web/cewl/$domain.txt --meta --meta_file $path/Assessment/Web/cewl/$domain.meta.txt --email --email_file $path/Assessment/Web/cewl/$domain.emails.txt $domain
	wget -t 5 -e robots=off --wait 1 -nd -r -A pdf,doc,docx,xls,xlsx,old,bac,bak,bc -P $path/Assessment/Web/web_docs $domain
	dig $domain NS > $path/Identification/DNS/$domain.nameserver.txt
	dig $domain MX > $path/Identification/DNS/$domain.mailserver.txt
	dnsenum --threads 20 -f $wordlists/DNS/deepmagic.com_top50kprefixes.txt -u a -r -p 15 -s 15 --subfile $path/Identification/DNS/$domain.subdomains.txt -o $path/Identification/DNS/$domain.dnsenum.xml $domain 2>&1 |tee $path/Identification/DNS/$domain.dnsenum.txt
done 10<$domains

$scriptloc/whois.pl -i $domains -o $path/Identification/WHOIS
$scriptloc/Whois_LockandExpiration.pl -i $domains -o Identification/WHOIS/WhoisLockAndExpiration-$client.csv
$scriptloc/DNSDigger.pl -d $domains > Identification/DNS/DNSDigger-$client.csv
$scriptloc/recon-ng_script.sh $domains $client