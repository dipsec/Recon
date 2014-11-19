while read -u 10 domain; do
echo $domain
ping -c 1 $domain |cut -d' ' -f2,3 | grep -v statistics | grep -v packets >> domains-found.tmp
done 10< domains-found.txt
grep -v ping domains-found.tmp |sort -u > domains-found2.tmp
sed '/^$/d' domains-found2.tmp > domains-found-resolved.txt
rm *.tmp
