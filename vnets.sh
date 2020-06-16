#!/bin/bash

if [ -z "$1" ]
then
    echo "Please supply location as arg, ex: ./list-rgs eastus2"
    exit 1
fi
location="$1"

vnet_json=`az network vnet list --query "[?location=='${location}']" | json_pp`
vnetlist=`echo "${vnet_json}" | jq -r '.[] | .name'`
vnet_count=$((`echo ${vnet_json} | jq '. | length'`-1))
#'
##
myvnet='VNET-E2US'
for I in `seq 0 "${vnet_count}"`; do
  this_vnet=`echo "$vnet_json" | jq -r --arg 'I' $I '.[$I | tonumber] | .name'`
  if [[ "${this_vnet}" == "${myvnet}" ]]; then
    echo -n "${I}: "
    echo "${this_vnet}"
  fi
done
