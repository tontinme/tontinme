#!/bin/sh
#operation=$2
choose=$1
#for i in 1 2
#do
        sh test.sh
        expect "*y/N*"
        send "$choose\r"
#       echo $i
#done
