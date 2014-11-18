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

mkdir -p harvester
mkdir -p robots
mkdir -p cewl
mkdir -p web_docs

while read -u 10 ip; do
	echo $ip
	theharvester -d $ip -b all -vn -f harvester/$ip.harvester.xml 2>&1 |tee harvester/$ip.harvester.txt
	sed -n '/Emails found:/,/Hosts found/p' harvester/$ip.harvester.txt |grep -v Hosts |grep -v Emails|grep -v '-' > harvester/$ip.emails.txt
	sed -n '/Hosts found in search engines/,/active queries/p' harvester/$ip.harvester.txt |grep -v Hosts |grep -v queries|grep -v '-' |sed -e 's/:/,/g' > harvester/$ip.SearchEngines.txt
	sed -n '/Hosts found after reverse lookup/,/Virtual hosts/p' harvester/$ip.harvester.txt |grep -v Hosts |grep -v hosts|grep -v '-' |sed -e 's/:/,/g' > harvester/$ip.ReverseLookup.txt
	sed -n '/Virtual hosts/,$p' harvester/$ip.harvester.txt |grep -v Hosts |grep -v hosts|grep -v '=' > harvester/$ip.VirtualHosts.txt
	wget -t 5 $ip/robots.txt -O robots/$ip.robots.txt
	cewl --count --verbose -m 8 -o --write cewl/$ip.txt --meta --meta_file cewl/$ip.meta.txt --email --email_file cewl/$ip.emails.txt $ip
	wget -t 5 -e robots=off --wait 1 -nd -r -A pdf,doc,docx,xls,xlsx,old,bac,bak,bc -P web_docs $ip
done 10<$1
