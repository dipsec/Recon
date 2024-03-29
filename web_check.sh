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
# Usage
# -----
# web_check.sh [OPTION] [FILENAME]
# web_check.sh -nhc domains.txt
# web_check.sh -a domains.txt
#  OPTIONS"
#   -n :Nikto Scanner"
#   -h :Harvester"
#   -v :nmap Virtual Host NSE"
#   -c :cewl web scrape for passwords"
#   -w :Web Scrape for Documents"
#   -r :robots.txt Download"
#   -s :sslscan/sslyze SSL Checks"
#   -a :All Checks"
#
#
# Changelog
# ---------
# version 2.1
# Fixed SSL Scan bugs
# version 2.0
# Added:
# Selection of scans to perform
# --help option
# Fixed bugs in sort and remove dups function
#
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
# Option to change custom script location

dir=$(pwd)

# Check 2 arguments are given #
if [[ $# -lt 2 ]] || [[ $1 == --help ]] || [[ $1 != -*[nhvcwrsa]* ]]; then
        echo "Usage : web_check.sh [OPTION] [FILENAME]"
        echo "  web_check.sh -nhc domains.txt"
        echo "  web_check.sh -a domains.txt"
        echo "========================================"
	echo "  OPTIONS"
	echo "   -n	:Nikto Scanner"
	echo "   -h	:Harvester"
	echo "   -v	:nmap Virtual Host NSE"
	echo "   -c	:cewl web scrape for passwords"
	echo "   -w	:Web Scrape for Documents"
	echo "   -r 	:robots.txt Download"
	echo "   -s	:sslscan/sslyze SSL Checks"
    	echo "   -a 	:All Checks"
        exit
fi

# Check the given file is exist #
if [ ! -f $2 ]
then
        echo "Filename \"$2\" doesn't exist"
        exit
fi

option=$1

dos2unix -n $2 domains.tmp
file=domains.tmp

#if [[ -z $1 ]]; then
#	echo Usage: web_check.sh [FILENAME]
#	echo;
#	exit
#fi

while read -u 10 f; do
   if [[ $f == http* ]] || [[ -z $f ]]; then
   dumb=1
   else
        echo File Format is Incorrect!
        echo Filename format: http://IP:Port or http://Hostname:Port
        echo;
        exit
   fi
done 10< $file

custtoolloc=/toolsv3/Assessment/Access/Web


# Sort and Remove Dups in original list
sort -u $file > $file.tmp
sed '/^$/d' $file.tmp > $file

#echo $file
mkdir -p $dir/web-check
mkdir -p $dir/web-check/web_docs
mkdir -p $dir/web-check/cewl
mkdir -p $dir/web-check/cewl/IPs
mkdir -p $dir/web-check/cewl/hostnames
mkdir -p $dir/web-check/hostfiles
mkdir -p $dir/web-check/nikto
mkdir -p $dir/web-check/nikto/IPs
mkdir -p $dir/web-check/nikto/hostnames
mkdir -p $dir/web-check/robots
mkdir -p $dir/web-check/sslscan
mkdir -p $dir/web-check/sslscan/IPs
mkdir -p $dir/web-check/sslscan/hostnames
mkdir -p $dir/web-check/sslyze
mkdir -p $dir/web-check/sslyze/IPs
mkdir -p $dir/web-check/sslyze/hostnames
mkdir -p $dir/web-check/nmap-SSL/IPs
mkdir -p $dir/web-check/nmap-SSL/hostnames
mkdir -p $dir/web-check/harvester
mkdir -p $dir/web-check/nmap

CreateHostFiles()
{
# Split file into HTTP & HTTPS
# SSL Hosts https://IP:Port
cat $file |grep https > $dir/web-check/hostfiles/https_hosts.txt
# Non-SSL Hosts http://IP:Port
cat $file |grep -v https > $dir/web-check/hostfiles/http_hosts.txt

while read -u 10 h; do
#Split HTTPS into Hostnames and IPs
#	echo $h |grep https |cut -d"/" -f3 |cut -d"." -f2
	https=$(echo $h |cut -d"/" -f3 |cut -d"." -f2)
	if [[ $https == *[0-9]* ]]; then
		echo $h >> $dir/web-check/hostfiles/HTTPSIPs.txt
	else
		echo $h >> $dir/web-check/hostfiles/HTTPSHostnames.txt
	fi
done 10< $dir/web-check/hostfiles/https_hosts.txt

while read -u 10 h; do
#Split HTTP into Hostnames and IPs    http://host.com:Port
#	echo $h |grep -v https |cut -d"/" -f3 |cut -d"." -f1
	http=$(echo $h |cut -d"/" -f3 |cut -d"." -f2)
	if [[ $http == *[0-9]* ]]; then
	        echo $h >>  $dir/web-check/hostfiles/HTTPIPs.txt
	else
	        echo $h >> $dir/web-check/hostfiles/HTTPHostnames.txt
	fi
done 10< $dir/web-check/hostfiles/http_hosts.txt

# Get Hostname from cert
ruby $custtoolloc/getcertcn.rb $dir/web-check/hostfiles/HTTPSIPs.txt > $dir/web-check/getcertcn.hostnames.txt
ruby $custtoolloc/getcertcn.rb $dir/web-check/hostfiles/HTTPSHostnames.txt >> $dir/web-check/getcertcn.hostnames.txt
#cat getcertcn.hostnames.txt |cut -d"," -f2 |grep -v ERROR > hostfiles/SSL_Hostnames.txt

# Get Hostname from DNS (HTTP)
while read -u 10 d; do
        ip=$(echo $d |cut -d"/" -f3 |cut -d":" -f1)
        port=$(echo $d |cut -d"/" -f3 | cut -d":" -f2)
        dig +short -x $ip | xargs echo -n >> $dir/web-check/hostfiles/HTTPHostnames.tmp
        sed -i 's/[.\t]*$//' $dir/web-check/hostfiles/HTTPHostnames.tmp
        echo :$port >> $dir/web-check/hostfiles/HTTPHostnames.tmp
	sed -i '/:\/\/:/d' $dir/web-check/hostfiles/HTTPHostnames.tmp
#	sed -ni '/^\(:80\)$/!p' hostfiles/HTTPHostnames.tmp
done 10< $dir/web-check/hostfiles/HTTPIPs.txt
cat $dir/web-check/hostfiles/HTTPHostnames.tmp |sed 's/^/http:\/\//g' > $dir/web-check/hostfiles/HTTPHostnames2.tmp #txt
sed -i '/:\/\/:/d' $dir/web-check/hostfiles/HTTPHostnames2.tmp #txt
cat $dir/web-check/hostfiles/HTTPHostnames2.tmp |grep -v 'connection timed out' >> $dir/web-check/hostfiles/HTTPHostnames.txt

# Get Hostname from DNS (HTTPS)
while read -u 10 s; do
        ip=$(echo $s |cut -d"/" -f3 | cut -d":" -f1)
        port=$(echo $s |cut -d"/" -f3 | cut -d":" -f2)
        dig +short -x $ip | xargs echo -n >> $dir/web-check/hostfiles/HTTPSHostnames.tmp
        sed -i 's/[.\t]*$//' $dir/web-check/hostfiles/HTTPSHostnames.tmp
        echo :$port >> $dir/web-check/hostfiles/HTTPSHostnames.tmp
#	sed -ni '/^\(:443\)$/!p' hostfiles/HTTPSHostnames.tmp
done 10< $dir/web-check/hostfiles/HTTPSIPs.txt
# SSL hostname
# cat hostfiles/HTTPSHostnames.tmp > hostfiles/HTTPSHostnames.txt
# SSL https://hostname
cat $dir/web-check/hostfiles/HTTPSHostnames.tmp |sed 's/^/https:\/\//g' > $dir/web-check/hostfiles/HTTPSHostnames2.tmp #txt
sed -i '/:\/\/:/d' $dir/web-check/hostfiles/HTTPSHostnames2.tmp #txt
cat $dir/web-check/hostfiles/HTTPSHostnames2.tmp |grep -v 'connection timed out' >> $dir/web-check/hostfiles/HTTPSHostnames.txt
}

RemoveDups()
{
# Removes duplicate entries and blank lines
	sort -u $dir/web-check/hostfiles/HTTPHostnames.txt > $dir/web-check/hostfiles/HTTPHostnames.txt.tmp
	sed '/^$/d' $dir/web-check/hostfiles/HTTPHostnames.txt.tmp > $dir/web-check/hostfiles/HTTPHostnames.txt
	sort -u $dir/web-check/hostfiles/HTTPIPs.txt > $dir/web-check/hostfiles/HTTPIPs.txt.tmp
	sed '/^$/d' $dir/web-check/hostfiles/HTTPIPs.txt.tmp > $dir/web-check/hostfiles/HTTPIPs.txt
	sort -u $dir/web-check/hostfiles/HTTPSHostnames.txt > $dir/web-check/hostfiles/HTTPSHostnames.txt.tmp
	sed '/^$/d' $dir/web-check/hostfiles/HTTPSHostnames.txt.tmp > $dir/web-check/hostfiles/HTTPSHostnames.txt
	sort -u $dir/web-check/hostfiles/HTTPSIPs.txt > $dir/web-check/hostfiles/HTTPSIPs.txt.tmp
	sed '/^$/d' $dir/web-check/hostfiles/HTTPSIPs.txt.tmp > $dir/web-check/hostfiles/HTTPSIPs.txt
	rm -f $dir/web-check/hostfiles/*.tmp
	rm -f $dir/web-check/*.tmp
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
        if [[ $option == *[r]* ]] || [[ $option == *[a]* ]]; then wget -t 5 $h/robots.txt -O $dir/web-check/robots/$ip.$port.robots.txt; fi
        if [[ $option == *[c]* ]] || [[ $option == *[a]* ]]; then cewl --count --verbose --write $dir/web-check/cewl/hostnames/$ip.$port.cewl.txt --meta --meta_file $dir/web-check/cewl/hostnames/$ip.$port.cewl.meta.txt --email --email_file $dir/web-check/cewl/hostnames/$ip.$port.cewl.emails.txt $h; fi
        if [[ $option == *[v]* ]] || [[ $option == *[a]* ]]; then nmap --script http-vhosts -p $port $ip -oA $dir/web-check/nmap/$ip.$port; fi
        if [[ $option == *[h]* ]] || [[ $option == *[a]* ]]; then
        	theharvester -d $ip -b all -vn -f $dir/web-check/harvester/$ip.html 2>&1 | tee $dir/web-check/harvester/$ip.txt
            sed -n '/Emails found:/,/Hosts found/p' $dir/web-check/harvester/$ip.txt |grep -v Hosts |grep -v Emails|grep -v '-' > $dir/web-check/harvester/$ip.emails.txt
            sed -n '/Hosts found in search engines/,/active queries/p' $dir/web-check/harvester/$ip.txt |grep -v Hosts |grep -v queries|grep -v '-' |sed -e 's/:/,/g' > $dir/web-check/harvester/$ip.SearchEngine.csv
            sed -n '/Hosts found after reverse lookup/,/Virtual hosts/p' $dir/web-check/harvester/$ip.txt |grep -v Hosts |grep -v hosts|grep -v '-' |sed -e 's/:/,/g' > $dir/web-check/harvester/$ip.ReverseHosts.csv
            sed -n '/Virtual hosts/,$p' $dir/web-check/harvester/$ip.txt |grep -v Hosts |grep -v hosts|grep -v '=' > $dir/web-check/harvester/$ip.VirtualHosts.txt
        fi
        if [[ $option == *[n]* ]] || [[ $option == *[a]* ]]; then nikto -host $h -output $dir/web-check/nikto/hostnames/nikto.$ip.$port.txt; fi
        if [[ $option == *[w]* ]] || [[ $option == *[a]* ]]; then wget -t 5 -e robots=off --wait 1 -nd -r -A pdf,doc,docx,xls,xlsx,old,bac,bak,bc -P $dir/web-check/web_docs $h; fi
        echo;
done 10< $dir/web-check/hostfiles/HTTPHostnames.txt
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
        if [[ $option == *[r]* ]] || [[ $option == *[a]* ]]; then wget -t 5 $sh/robots.txt -O $dir/web-check/robots/$ship.$shport.robots.txt; fi
        if [[ $option == *[c]* ]] || [[ $option == *[a]* ]]; then cewl --count --verbose --write $dir/web-check/cewl/hostnames/$ship.$shport.cewl.txt --meta --meta_file $dir/web-check/cewl/hostnames/$ship.$shport.cewl.meta.txt --email --email_file $dir/web-check/cewl/hostnames/$ship.$shport.cewl.emails.txt $sh; fi
        if [[ $option == *[v]* ]] || [[ $option == *[a]* ]]; then nmap --script http-vhosts -p $shport $ship -oA $dir/web-check/nmap/$ship.$shport; fi
        if [[ $option == *[h]* ]] || [[ $option == *[a]* ]]; then
            theharvester -d $ship -b all -vn -f $dir/web-check/harvester/$ship.html 2>&1 | tee $dir/web-check/harvester/$ship.txt
            sed -n '/Emails found:/,/Hosts found/p' $dir/web-check/harvester/$ip.txt |grep -v Hosts |grep -v Emails|grep -v '-' > $dir/web-check/harvester/$ship.emails.txt
            sed -n '/Hosts found in search engines/,/active queries/p' $dir/web-check/harvester/$ip.txt |grep -v Hosts |grep -v queries|grep -v '-' |sed -e 's/:/,/g' > $dir/web-check/harvester/$ship.SearchEngine.csv
            sed -n '/Hosts found after reverse lookup/,/Virtual hosts/p' $dir/web-check/harvester/$ip.txt |grep -v Hosts |grep -v hosts|grep -v '-' |sed -e 's/:/,/g' > $dir/web-check/harvester/$ship.ReverseHosts.csv
            sed -n '/Virtual hosts/,$p' $dir/web-check/harvester/$ip.txt |grep -v Hosts |grep -v hosts|grep -v '=' > $dir/web-check/harvester/$ship.VirtualHosts.txt
        fi
        if [[ $option == *[n]* ]] || [[ $option == *[a]* ]]; then nikto -host $sh -output $dir/web-check/nikto/hostnames/nikto.$ship.$shport.txt; fi
        if [[ $option == *[w]* ]] || [[ $option == *[a]* ]]; then wget -t 5 -e robots=off --wait 1 -nd -r -A pdf,doc,docx,xls,xlsx,old,bac,bak,bc -P $dir/web-check/web_docs $sh; fi
        if [[ $option == *[s]* ]] || [[ $option == *[a]* ]]; then 
            sslscan --no-failed --xml=$dir/web-check/sslscan/hostnames/sslscan_$ship.$shport.xml $ship:$shport 2>&1 | tee $dir/web-check/sslscan/hostnames/sslscan_$ship.$shport.txt
            sslyze --reneg --compression --hide_rejected_ciphers --xml_out=$dir/web-check/sslyze/hostnames/sslyze_$ship.$shport.xml $ship:$shport 2>&1 | tee $dir/web-check/sslyze/hostnames/sslyze_$ship.$shport.txt
            nmap -PN --script ssl-enum-ciphers -p $shport $ship -oA $dir/web-check/nmap-SSL/hostnames/nmap_$ship.$shport
        fi
        echo;
done 10< $dir/web-check/hostfiles/HTTPSHostnames.txt
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
	if [[ $option == *[r]* ]] || [[ $option == *[a]* ]]; then wget -t 5 $h/robots.txt -O $dir/web-check/robots/$ip.$port.robots.txt; fi
	if [[ $option == *[c]* ]] || [[ $option == *[a]* ]]; then cewl --count --verbose --write $dir/web-check/cewl/IPs/$ip.$port.cewl.txt --meta --meta_file $dir/web-check/cewl/IPs/$ip.$port.cewl.meta.txt --email --email_file $dir/web-check/cewl/IPs/$ip.$port.cewl.emails.txt $h; fi
	if [[ $option == *[v]* ]] || [[ $option == *[a]* ]]; then nmap --script http-vhosts -p $port $ip -oA $dir/web-check/nmap/$ip.$port; fi
	if [[ $option == *[n]* ]] || [[ $option == *[a]* ]]; then nikto -host $h -output $dir/web-check/nikto/IPs/nikto.$ip.$port.txt; fi
	if [[ $option == *[w]* ]] || [[ $option == *[a]* ]]; then wget -t 5 -e robots=off --wait 1 -nd -r -A pdf,doc,docx,xls,xlsx,old,bac,bak,bc -P $dir/web-check/web_docs $h; fi
	echo;
done 10< $dir/web-check/hostfiles/HTTPIPs.txt
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
    if [[ $option == *[r]* ]] || [[ $option == *[a]* ]]; then wget -t 5 $s/robots.txt -O $dir/web-check/robots/$sip.$sport.robots.txt; fi
    if [[ $option == *[c]* ]] || [[ $option == *[a]* ]]; then cewl --count --verbose --write $dir/web-check/cewl/IPs/$sip.$sport.cewl.txt --meta --meta_file $dir/web-check/cewl/IPs/$sip.$sport.cewl.meta.txt --email --email_file $dir/web-check/cewl/IPs/$sip.$sport.cewl.emails.txt $s; fi
    if [[ $option == *[v]* ]] || [[ $option == *[a]* ]]; then nmap --script http-vhosts -p $sport $sip -oA $dir/web-check/nmap/$sip.$sport; fi
    if [[ $option == *[n]* ]] || [[ $option == *[a]* ]]; then nikto -host $s -output $dir/web-check/nikto/IPs/nikto.$sip.txt; fi
    if [[ $option == *[w]* ]] || [[ $option == *[a]* ]]; then wget -t 5 -e robots=off --wait 1 -nd -r -A pdf,doc,docx,xls,xlsx,old,bac,bak,bc -P $dir/web-check/web_docs $s; fi
    if [[ $option == *[s]* ]] || [[ $option == *[a]* ]]; then 
        sslscan --no-failed --xml=$dir/web-check/sslscan/IPs/sslscan_$sip.$sport.xml $sip:$sport 2>&1 | tee $dir/web-check/sslscan/IPs/sslscan_$sip.$sport.txt
        sslyze --reneg --compression --hide_rejected_ciphers --xml_out=$dir/web-check/sslyze/IPs/sslyze_$sip.$sport.xml $sip:$sport 2>&1 | tee $dir/web-check/sslyze/IPs/sslyze_$sip.$sport.txt
        nmap -PN --script ssl-enum-ciphers -p $sport $sip -oA $dir/web-check/nmap-SSL/IPs/nmap_$sip.$sport
    fi
    echo;
done 10< $dir/web-check/hostfiles/HTTPSIPs.txt
}

echo ----------- Creating Files -----------
cat $file
CreateHostFiles
echo ----------- Removing Duplicate Entries -----------
RemoveDups
echo HTTP Hosts
cat $dir/web-check/hostfiles/HTTPHostnames.txt
echo HTTPS Hosts
cat $dir/web-check/hostfiles/HTTPSHostnames.txt
echo ----------- Performing Recon Against Hostnames ---------------
HTTPHostInfo
SSLHostnamesInfo
echo ----------- Performing Recon Against IP Addresses -------------
HTTPInfo
SSLInfo

echo -e "\e[0m"
ruby $custtoolloc/getRedirects.rb -i $dir/web-check/hostfiles/HTTPIPs.txt -o $dir/web-check/http_redirects.csv
ruby $custtoolloc/getRedirects.rb -i $dir/web-check/hostfiles/HTTPSIPs.txt -o $dir/web-check/https_redirects.csv
ruby $custtoolloc/getRedirects.rb -i $dir/web-check/hostfiles/HTTPSHostnames.txt -o $dir/web-check/SecureHostnames_redirects.csv
ruby $custtoolloc/getRedirects.rb -i $dir/web-check/hostfiles/HTTPHostnames.txt -o $dir/web-check/Hostnames_redirects.csv

xsltproc /toolslinux/exploits/ssl/parse_sslscan/sslscan.xsl $dir/web-check/sslscan/hostnames/*.xml > $dir/web-check/sslscan/hostnames/sslscan_parsed.txt
cat $dir/web-check/sslscan/hostnames/sslscan_parsed.txt | awk -F',' '$5<112' > $dir/web-check/sslscan/hostnames/sslscan_weak.txt
cat $dir/web-check/sslscan/hostnames/sslscan_parsed.txt | grep -B 1 "renegotiation supported=\"1\"" | grep host | cut -d "\"" -f 2,4| sed 's/"/:/g' > $dir/web-check/sslscan/hostnames/sslscan_renegotiation.txt
cat $dir/web-check/sslscan/hostnames/sslscan_parsed.txt | grep "vulnerable=\"1\"" > $dir/web-check/sslscan/hostnames/sslscan_vulnerable.txt
cat $dir/web-check/sslscan/hostnames/sslscan_parsed.txt | grep "SSL" > $dir/web-check/sslscan/hostnames/sslscan_SSL.txt
cat $dir/web-check/sslscan/hostnames/sslscan_parsed.txt | grep "RC4" > $dir/web-check/sslscan/hostnames/sslscan_RC4.txt

cat $dir/web-check/nmap-SSL/hostnames/*.nmap > $dir/web-check/nmap-SSL/hostnames/nmap.combined.txt
cat $dir/web-check/nmap-SSL/hostnames/nmap.combined.txt | grep weak > $dir/web-check/nmap-SSL/hostnames/nmap.combined.weak.txt
cat $dir/web-check/nmap-SSL/hostnames/nmap.combined.txt | grep DHE_EXPORT > $dir/web-check/nmap-SSL/hostnames/nmap.combined.logjam.txt
cat $dir/web-check/nmap-SSL/hostnames/nmap.combined.txt | grep SSL > $dir/web-check/nmap-SSL/hostnames/nmap.combined.SSL.txt
cat $dir/web-check/nmap-SSL/hostnames/nmap.combined.txt | grep RC4 > $dir/web-check/nmap-SSL/hostnames/nmap.combined.RC4.txt

cat $dir/web-check/nmap-SSL/IPs/*.nmap > $dir/web-check/nmap-SSL/IPs/nmap.combined.nmap
cat $dir/web-check/nmap-SSL/IPs/nmap.combined.nmap | grep weak > $dir/web-check/nmap-SSL/IPs/nmap.combined.weak.txt
cat $dir/web-check/nmap-SSL/IPs/nmap.combined.nmap | grep DHE_EXPORT > $dir/web-check/nmap-SSL/IPs/nmap.combined.logjam.txt
cat $dir/web-check/nmap-SSL/IPs/nmap.combined.nmap | grep SSL > $dir/web-check/nmap-SSL/IPs/nmap.combined.SSL.txt
cat $dir/web-check/nmap-SSL/IPs/nmap.combined.nmap | grep RC4 > $dir/web-check/nmap-SSL/IPs/nmap.combined.RC4.txt

xsltproc /toolslinux/exploits/ssl/parse_sslscan/sslscan.xsl $dir/web-check/sslscan/IPs/*.xml > $dir/web-check/sslscan/IPs/sslscan_parsed.txt
cat $dir/web-check/sslscan/IPs/sslscan_parsed.txt | awk -F',' '$5<112' > $dir/web-check/sslscan/IPs/sslscan_parsed.weak.txt
cat $dir/web-check/sslscan/IPs/sslscan_parsed.txt | grep -B 1 "renegotiation supported=\"1\"" | grep host | cut -d "\"" -f 2,4| sed 's/"/:/g' > $dir/web-check/sslscan/IPs/sslscan_parsed.renegotiation.txt
cat $dir/web-check/sslscan/IPs/sslscan_parsed.txt | grep "vulnerable=\"1\"" >$dir/web-check/sslscan/IPs/sslscan_parsed.vulnerable.txt
cat $dir/web-check/sslscan/IPs/sslscan_parsed.txt | grep "SSL" > $dir/web-check/sslscan/IPs/sslscan_parsed.SSL.txt
cat $dir/web-check/sslscan/IPs/sslscan_parsed.txt | grep "RC4" > $dir/web-check/sslscan/IPs/sslscan_parsed.RC4.txt

exit
