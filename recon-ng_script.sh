#! /bin/bash

# recon-ng_script - Creates recon-ng resource file
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
# Creates recon-ng resource file from a template file.
#
#
# Changelog
# ---------
# version 1.0
# Intro script
#
# TO DO
# ---------
# Help file
# link recon with recon-ng - pass multiple params

if [[ $# -lt 4 ]] || [[ $1 == --help ]]; then
	echo Usage: recon-ng_script.sh [DOMAINS FILE NAME] [CLIENT NAME] [EPA BLOCK FOLDER] [SCRIPT LOCATION]
	echo;
	exit
fi


client=$2
folder=$3
scriptloc=$4
path=~/$folder/$client/Recon/Identification/recon-ng


mkdir -p ~/$folder
mkdir -p ~/$folder/$client
mkdir -p ~/$folder/$client/Recon
mkdir -p ~/$folder/$client/Recon/Identification
mkdir -p $path

while read -u 10 domain; do
	sed -e "s/CLIENT/$client/g" $scriptloc/recon-ng_temp.rc > $path/$client.tmp
	sed -e "s/DOMAIN/$domain/g" $path/$client.tmp > $path/$domain.recon-ng.rc
done 10<$1
rm $path/*.tmp

for f in $path/*.rc; do recon-ng -r $f; done

cp /root/.recon-ng/workspaces/$client/results.csv $path/recon-ng.results.csv
