#!/bin/sh
echo "do you want to do this? y/N"
read answer
if [[ $answer = "y" || $answer = "Y" || $answer = "yes" ]]
#if [[ $answer = "y" ]]
then
        echo "processing..."
else
        echo "you choose exit!"
fi
