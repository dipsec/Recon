#!/bin/bash

# web_check - Automates Basic Web Checks
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
# version 1.3
# Split host file into IPs and Hostnames
#
# version=1.2
# Added:
# Virtual Host Check - harvester
# Email Check - harvester
# Custom Tool Directory variable
#
# version=1.1
# Added:
# dig reverse lookup
# NMAP http-vhosts NSE
# Removing duplicate addresses and ips
#
# version=1.0
# Added:
# nikto check
# wget robots.txt
# website scraping (doc, pdf, bak)
# SSL Cert Checks
#
# TO DO
# ---------
# check if IP or hostname
# Options to choose which scan - rev 2.0
# Possibly pass scan option parameters through script call


if [[ -z $1 ]]; then
	echo Usage: web_check.sh [FILE NAME]
	echo;
	exit
fi

while read -u 10 f; do
   if [[ $f == http* ]] || [[ -z $f ]]; then
   dumb=1
   else
        echo File Format is Incorrect!
        echo Filename format: http://IP:Port or http://Hostname:Port
        echo;
        exit
   fi
done 10< $1

file=$1
# Sort and Remove Dups in original list
sort -u $file > $file.tmp
sed '/^$/d' $file.tmp > $file

#echo $file

mkdir -p web_docs
mkdir -p cewl
mkdir -p cewl/IPs
mkdir -p cewl/hostnames
mkdir -p hostfiles
mkdir -p nikto
mkdir -p nikto/IPs
mkdir -p nikto/hostnames
mkdir -p robots
mkdir -p sslscan
mkdir -p sslscan/IPs
mkdir -p sslscan/hostnames
mkdir -p sslyze
mkdir -p sslyze/IPs
mkdir -p sslyze/hostnames
mkdir -p harvester
mkdir -p nmap

custtoolloc=/root/toolsv3/Assessment/Access/Web

CreateHostFiles()
{
# Split file into HTTP & HTTPS
# SSL Hosts https://IP:Port
cat $file |grep https > hostfiles/https_hosts.txt
# Non-SSL Hosts http://IP:Port
cat $file |grep -v https > hostfiles/http_hosts.txt

while read -u 10 h; do
#Split HTTPS into Hostnames and IPs
#	echo $h |grep https |cut -d"/" -f3 |cut -d"." -f2
	https=$(echo $h |cut -d"/" -f3 |cut -d"." -f2)
	if [[ $https == *[0-9]* ]]; then
		echo $h >> hostfiles/HTTPSIPs.txt
	else
		echo $h >> hostfiles/HTTPSHostnames.txt
	fi
done 10< hostfiles/https_hosts.txt

while read -u 10 h; do
#Split HTTP into Hostnames and IPs    http://host.com:Port
#	echo $h |grep -v https |cut -d"/" -f3 |cut -d"." -f1
	http=$(echo $h |cut -d"/" -f3 |cut -d"." -f2)
	if [[ $http == *[0-9]* ]]; then
	        echo $h >>  hostfiles/HTTPIPs.txt
	else
	        echo $h >> hostfiles/HTTPHostnames.txt
	fi
done 10< hostfiles/http_hosts.txt

####################### VERIFY IF BELOW IS NEEDED ##########################
# HTTPS Hosts IP:Port
#cat $file |grep https |cut -d"/" -f3 > hostfiles/sslhosts.txt
# Non-SSL Hosts IP:Port
#cat $file |grep -v https |cut -d"/" -f3 > hostfiles/hosts.txt
###########################################################################

# Get Hostname from cert
ruby $custtoolloc/getcertcn.rb hostfiles/HTTPSIPs.txt > getcertcn.hostnames.txt
ruby $custtoolloc/getcertcn.rb hostfiles/HTTPSHostnames.txt >> getcertcn.hostnames.txt
#cat getcertcn.hostnames.txt |cut -d"," -f2 |grep -v ERROR > hostfiles/SSL_Hostnames.txt

# Get Hostname from DNS (HTTP)
while read -u 10 d; do
        ip=$(echo $d | cut -d":" -f1)
        port=$(echo $d | cut -d":" -f2)
        dig +short -x $ip | xargs echo -n >> hostfiles/HTTPHostnames.tmp
        sed -i 's/[.\t]*$//' hostfiles/HTTPHostnames.tmp
        echo :$port >> hostfiles/HTTPHostnames.tmp
	sed -i '/:\/\/:/d' hostfiles/HTTPHostnames.tmp
#	sed -ni '/^\(:80\)$/!p' hostfiles/HTTPHostnames.tmp
done 10< hostfiles/HTTPIPs.txt
cat hostfiles/HTTPHostnames.tmp |sed 's/^/http:\/\//g' > hostfiles/HTTPHostnames.tmp #txt
sed -i '/:\/\/:/d' hostfiles/HTTPHostnames.tmp #txt
cat hostfiles/HTTPHostnames.tmp |grep -v 'connection timed out' >> hostfiles/HTTPHostnames.txt

# Get Hostname from DNS (HTTPS)
while read -u 10 s; do
        ip=$(echo $s | cut -d":" -f1)
        port=$(echo $s | cut -d":" -f2)
        dig +short -x $ip | xargs echo -n >> hostfiles/HTTPSHostnames.tmp
        sed -i 's/[.\t]*$//' hostfiles/HTTPSHostnames.tmp
        echo :$port >> hostfiles/HTTPSHostnames.tmp
#	sed -ni '/^\(:443\)$/!p' hostfiles/HTTPSHostnames.tmp
done 10< hostfiles/HTTPSIPs.txt
# SSL hostname
# cat hostfiles/HTTPSHostnames.tmp > hostfiles/HTTPSHostnames.txt
# SSL https://hostname
cat hostfiles/HTTPSHostnames.tmp |sed 's/^/https:\/\//g' > hostfiles/HTTPSHostnames.tmp #txt
sed -i '/:\/\/:/d' hostfiles/HTTPSHostnames.tmp #txt
cat hostfiles/HTTPSHostnames.tmp |grep -v 'connection timed out' >> hostfiles/HTTPSHostnames.txt
}

RemoveDups()
{
# Removes duplicate entries and blank lines
#	sort -u hostfiles/hosts.txt > hostfiles/hosts.txt.tmp
#	sed '/^$/d' hostfiles/hosts.txt.tmp > hostfiles/hosts.txt
	sort -u hostfiles/HTTPHostnames.txt > hostfiles/HTTPHostnames.txt.tmp
	sed '/^$/d' hostfiles/HTTPHostnames.txt.tmp > hostfiles/HTTPHostnames.txt
#	sort -u hostfiles/http_hosts.txt > hostfiles/http_hosts.txt.tmp
#	sed '/^$/d' hostfiles/http_hosts.txt.tmp > hostfiles/http_hosts.txt
	sort -u hostfiles/HTTPSHostnames.txt > hostfiles/HTTPSHostnames.txt.tmp
	sed '/^$/d' hostfiles/HTTPSHostnames.txt.tmp > hostfiles/HTTPSHostnames.txt
#	sort -u hostfiles/https_hosts.txt > hostfiles/https_hosts.txt.tmp
#	sed '/^$/d' hostfiles/https_hosts.txt.tmp > hostfiles/https_hosts.txt
#	sort -u hostfiles/SSL_Hostnames.txt > hostfiles/SSL_Hostnames.txt.tmp
#	sed '/^$/d' hostfiles/SSL_Hostnames.txt.tmp > hostfiles/SSL_Hostnames.txt
#	sort -u hostfiles/sslhosts.txt > hostfiles/sslhosts.txt.tmp
#	sed '/^$/d' hostfiles/sslhosts.txt.tmp > hostfiles/sslhosts.txt
	rm -f hostfiles/*.tmp
	rm -f *.tmp
}

########### Hostname Checks #############
HTTPHostInfo()
{
echo ------------------
echo HTTP Host Info
echo ------------------
while read -u 10 h; do
	echo -e "\e[91m $h"
        #Remove http
        ip=$(echo $h |  cut -d"/" -f3 | cut -d":" -f1)
        #remove port
        port=$(echo $h |  cut -d":" -f3)
        echo IP: $ip
        echo Port: $port
echo -e "\e[0m"
        wget -t 5 $h/robots.txt -O robots/$ip.$port.robots.txt
        cewl --count --verbose --write cewl/hostnames/$ip.$port.cewl.txt --meta --meta_file cewl/hostnames/$ip.$port.cewl.meta.txt --email --email_file cewl/hostnames/$ip.$port.cewl.emails.txt $h
        nmap --script http-vhosts -p $port $ip -oA nmap/$ip.$port
	theharvester -d $ip -b all -vn -f harvester/$ip.xml 2>&1 | tee harvester/$ip.txt
		sed -n '/Emails found:/,/Hosts found/p' harvester/$ip.txt |grep -v Hosts |grep -v Emails|grep -v '-' > harvester/$ip.emails.txt
		sed -n '/Hosts found in search engines/,/active queries/p' harvester/$ip.txt |grep -v Hosts |grep -v queries|grep -v '-' |sed -e 's/:/,/g' > harvester/$ip.SearchEngine.csv
		sed -n '/Hosts found after reverse lookup/,/Virtual hosts/p' harvester/$ip.txt |grep -v Hosts |grep -v hosts|grep -v '-' |sed -e 's/:/,/g' > harvester/$ip.ReverseHosts.csv
		sed -n '/Virtual hosts/,$p' harvester/$ip.txt |grep -v Hosts |grep -v hosts|grep -v '=' > harvester/$ip.VirtualHosts.txt
        nikto -host $h -output nikto/hostnames/nikto.$ip.$port.txt
        wget -t 5 -e robots=off --wait 1 -nd -r -A pdf,doc,docx,xls,xlsx,old,bac,bak,bc -P web_docs $h
        echo;
done 10< hostfiles/HTTPHostnames.txt
}

SSLHostnamesInfo()
{
echo ------------------
echo SSL Hosts
echo ------------------
while read -u 10 sh; do
        echo -e "\e[91m $sh"
        ship=$(echo $sh |  cut -d"/" -f3 | cut -d":" -f1)
        #remove port
        shport=$(echo $sh |  cut -d":" -f3)
        echo IP: $ship
        echo Port: $shport
echo -e "\e[0m"
        wget -t 5 $sh/robots.txt -O robots/$ship.$shport.robots.txt
        cewl --count --verbose --write cewl/hostnames/$ship.$shport.cewl.txt --meta --meta_file cewl/hostnames/$ship.$shport.cewl.meta.txt --email --email_file cewl/hostnames/$ship.$shport.cewl.emails.txt $sh
        nmap --script http-vhosts -p $shport $ship -oA nmap/$ship.$shport
        theharvester -d $ship -b all -vn -f harvester/$ship.xml 2>&1 | tee harvester/$ship.txt
                sed -n '/Emails found:/,/Hosts found/p' harvester/$ip.txt |grep -v Hosts |grep -v Emails|grep -v '-' > harvester/$ship.emails.txt
                sed -n '/Hosts found in search engines/,/active queries/p' harvester/$ip.txt |grep -v Hosts |grep -v queries|grep -v '-' |sed -e 's/:/,/g' > harvester/$ship.SearchEngine.csv
                sed -n '/Hosts found after reverse lookup/,/Virtual hosts/p' harvester/$ip.txt |grep -v Hosts |grep -v hosts|grep -v '-' |sed -e 's/:/,/g' > harvester/$ship.ReverseHosts.csv
                sed -n '/Virtual hosts/,$p' harvester/$ip.txt |grep -v Hosts |grep -v hosts|grep -v '=' > harvester/$ship.VirtualHosts.txt
         nikto -host $sh -output nikto/hostnames/nikto.$ship.$shport.txt
        wget -t 5 -e robots=off --wait 1 -nd -r -A pdf,doc,docx,xls,xlsx,old,bac,bak,bc -P web_docs $sh
        sslscan --no-failed --xml=sslscan/hostnames/sslscan_$ship.$shport.xml $ship:$shport
        sslyze $sh --reneg --compression --hide_rejected_ciphers --xml_out=sslyze/hostnames/sslyze_$ship.$shport.xml
        echo;
done 10< hostfiles/HTTPSHostnames.txt
}


############# IP Checks ################
HTTPInfo()
{
echo ------------------
echo HTTP Info
echo ------------------
while read -u 10 h; do
	echo -e "\e[91m $h"
	#Remove http
	ip=$(echo $h |  cut -d"/" -f3 | cut -d":" -f1)
	#remove port
	port=$(echo $h |  cut -d":" -f3)
        echo IP: $ip
        echo Port: $port
echo -e "\e[0m"
	wget -t 5 $h/robots.txt -O robots/$ip.$port.robots.txt
	cewl --count --verbose --write cewl/IPs/$ip.$port.cewl.txt --meta --meta_file cewl/IPs/$ip.$port.cewl.meta.txt --email --email_file cewl/IPs/$ip.$port.cewl.emails.txt $h
	nmap --script http-vhosts -p $port $ip -oA nmap/$ip.$port
	nikto -host $h -output nikto/IPs/nikto.$ip.$port.txt
	wget -t 5 -e robots=off --wait 1 -nd -r -A pdf,doc,docx,xls,xlsx,old,bac,bak,bc -P web_docs $h
	echo;
done 10< hostfiles/HTTPIPs.txt
}

SSLInfo()
{
echo ------------------
echo SSL Info
echo ------------------
while read -u 10 s; do
        echo -e "\e[91m $s"
	#remove https
        sip=$(echo $s |  cut -d"/" -f3 | cut -d":" -f1)
        #remove port
        sport=$(echo $s |  cut -d":" -f3)
        echo IP: $sip
        echo Port: $sport
echo -e "\e[0m"
        wget -t 5 $s/robots.txt -O robots/$sip.$sport.robots.txt
        cewl --count --verbose --write cewl/IPs/$sip.$sport.cewl.txt --meta --meta_file cewl/IPs/$sip.$sport.cewl.meta.txt --email --email_file cewl/IPs/$sip.$sport.cewl.emails.txt $s
	nmap --script http-vhosts -p $sport $sip -oA nmap/$sip.$sport
        nikto -host $s -output nikto/IPs/nikto.$sip.txt
        wget -t 5 -e robots=off --wait 1 -nd -r -A pdf,doc,docx,xls,xlsx,old,bac,bak,bc -P web_docs $s
        sslscan --no-failed --xml=sslscan/IPs/sslscan_$sip.$sport.xml $sip:$sport
        sslyze $s --reneg --compression --hide_rejected_ciphers --xml_out=sslyze/IPs/sslyze_$sip.$sport.xml
        echo;
done 10< hostfiles/HTTPSIPs.txt
}

echo ----------- Creating Files -----------
cat $file
CreateHostFiles
echo ----------- Removing Duplicate Entries -----------
RemoveDups
echo HTTP Hosts
cat hostfiles/HTTPHostnames.txt
echo HTTPS Hosts
cat hostfiles/HTTPSHostnames.txt

echo ----------- Performing Recon Against Hostnames ---------------
HTTPHostInfo
SSLHostnamesInfo
echo ----------- Performing Recon Against IP Addresses -------------
HTTPInfo
SSLInfo

echo -e "\e[0m"
ruby $custtoolloc/getRedirects.rb -i hostfiles/http_hosts.txt -o http_redirects.csv
ruby $custtoolloc/getRedirects.rb -i hostfiles/https_hosts.txt -o https_redirects.csv
ruby $custtoolloc/getRedirects.rb -i hostfiles/SSL_Hostnames.txt -o SecureHostnames_redirects.csv
ruby $custtoolloc/getRedirects.rb -i hostfiles/HTTPHostnames.txt -o Hostnames_redirects.csv
exit
