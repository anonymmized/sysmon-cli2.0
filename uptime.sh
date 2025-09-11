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

#1) up 45 secs
#2) up 12 min
#3) up 14:50 ✅
#4) up 2 days, 14:50
#5) up 120 days