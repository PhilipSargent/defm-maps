#!/bin/bash
# PMS 29-Novermber-2020 17:44
# runs fixdatesarc.awk on a load of folders
gawk -f fixdatespas.awk DFM*.PAS
exit

FILES="*"
echo $FILES

for f in $FILES
do
	echo
	echo $f
	for i in $f/*.PAS; do 
	 echo $i
	 # head -2 $i
	 gawk -f fixdatesarc.awk $i
	done
done