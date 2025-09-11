#!/bin/bash

number=$(w | head -n1 | awk '{print $3;}' | tr -d ',')
duration=$(w | head -n1 | awk '{print $4;}' | tr -d ',')

arr=("secs" "min" "days")

if [[ " ${arr[*]} " == *" $duration "* ]]; then
    echo "Активен либо более суток, либо менее часа"
else
    IFS=":" read -r hours minutes <<< "$number"
    echo "Активен $hours часов $minutes минут"
fi


#echo "$number:$duration"