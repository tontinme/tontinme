#!/bin/bash
if [ `cat config.txt | wc -l` != `cat config1.txt | wc -l` ]
then 
	echo -e "This file is different from  the origin file,Continue modify?(N/y):"
	read decision
	case $decision in
	"Y" | "y")
		:
		;;
	*)
		echo "leave now"
		exit
		;;	
	esac
fi
echo execute
