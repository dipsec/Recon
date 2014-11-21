while read -u 10 ip; do
        echo $ip
	echo $ip >> $1.reversed.txt
        dig +short -x $ip | xargs echo -n >> $1.reversed.txt
	echo " " >> $1.reversed.txt
	echo "--------------------------" >> $1.reversed.txt
done 10< $1
