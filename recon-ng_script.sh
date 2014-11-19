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

if [[ -z $1 ]]; then
	echo Usage: recon-ng_script.sh [DOMAINS FILE NAME] [CLIENT NAME]
	echo;
	exit
fi

if [[ -z $2 ]]; then
	echo Usage: recon-ng_script.sh [DOMAINS FILE NAME] [CLIENT NAME]
	echo;
	exit
fi

client=$2
##################### Replace Folder Location ######################
folder=in-epa-nov17
path=~/$folder/$2
##################### Replace Script Location ######################
scriptloc=/mnt/hgfs/isadmintools/GitHub/Recon

mkdir -p /root/$folder
mkdir -p $path
mkdir -p $path/Identification
mkdir -p $path/Identification/recon-ng

while read -u 10 domain; do
	sed -e "s/CLIENT/$client/g" $scriptloc/recon-ng_temp.rc > $path/Identification/recon-ng/$client.tmp
	sed -e "s/DOMAIN/$domain/g" $path/Identification/recon-ng/$client.tmp > $path/Identification/recon-ng/$domain.recon-ng.rc
done 10<$1
rm $path/Identification/recon-ng/*.tmp

for f in $path/Identification/recon-ng/*.rc; do recon-ng -r $f; done

cp /root/.recon-ng/workspaces/$client/results.csv $path/Identification/recon-ng/recon-ng.results.csv