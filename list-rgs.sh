#!/bin/bash
if [ -z "$1" ]
then
    echo "Please supply location as arg, ex: ./list-rgs eastus2"
    exit 1
fi
location="$1"
# az group list --query "[?location=='eastus2']" | grep name
myrgs=`/usr/bin/az group list --query "[?location=='${location}']" | json_pp | jq -r '.[] | .name'`
#echo "Found Resource Groups in $location:"
#echo "$myrgs"
if [ -z "$myrgs" ]
then
    echo "No RGs found in $location"
    exit 0
fi

echo "Select your RG:"
select rgsel in `echo ${myrgs}`;
do
    echo "You chose ${rgsel}"
    break
done
