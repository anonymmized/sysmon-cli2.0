#!/bin/bash

number=$(w | head -n1 | awk '{print $3;}' | tr -d ',')
duration=$(w | head -n1 | awk '{print $4;}' | tr -d ',')

echo "$number:$duration"