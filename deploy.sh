#!/bin/bash
. ./functions.sh

echo "
##############################################################################################################
#  _                         
# |_) _  __ __ _  _     _| _ 
# |_)(_| |  | (_|(_ |_|(_|(_|
#
# Quickstart WAF deployment in Microsoft Azure using Terraform and Ansible
#
##############################################################################################################
"

# Stop running when command returns error
set -e

PLAN="terraform.tfplan"
ANSIBLEINVENTORYDIR="ansible/inventory"
ANSIBLEINVENTORY="$ANSIBLEINVENTORYDIR/all"
DEBUG='false'
VERBOSE='false'
DEPLOY_LOCATION='eastus2'
DEPLOY_PREFIX=''
DEPLOY_TYPE=''
RESOURCE_GROUP='rg-cuda-waf'
CLOUD='Azure'
CLOUD_FOUND='False'

if ! options=$(getopt -o hdvr:p:l:c:t: \
        -l help,debug,verbose,rg:,password:,location:,cloud:,type: \
        -- "$@") #"
then
    # something went wrong, getopt will put out an error message for us
    exit 1
fi

set -- $options

while [ $# -gt 0 ]
do
    case $1 in
    -h|--help) 
                echo "WAF installer" 
                exit 0
                ;;
    -d|--debug) DEBUG='true' ;;
    -v|--verbose) DEBUG='true' ;;
    # for options with required arguments, an additional shift is required
    -r|--rg) RESOURCE_GROUP="$2" ; shift;;
    -l|--location) DEPLOY_LOCATION="$2" ; shift;;
    -p|--password) DEPLOY_PASSWORD="$2" ; shift;;
    -c|--cloud) CLOUD="$2" ; shift;;
    -t|--type) DEPLOY_TYPE="$2" ; shift;;
    (--) shift; break;;
    (-*) echo "$0: error - unrecognized option $1" 1>&2; exit 1;;
    (*) break;;
    esac
    shift
done

dprint "Debug on..."

## Verify cloud
dprint "Cloud found before test: $CLOUD_FOUND"
cloud_cli_available "$CLOUD"
dprint "Cloud found after test: $CLOUD_FOUND"
if [ "$CLOUD_FOUND" = "True" ]
then
    dprint "$CLOUD availability: $CLOUD_FOUND"
else
    echo "Did not find commands for cloud: $CLOUD"
    exit 1
fi

## Choose deployment type: new or existing infrastructure?
if [ -z "$DEPLOY_TYPE" ]
then
    # Input type 
    echo -n "Enter type: [n]ew or [e]xisting (<enter>=new): "
    stty_orig=`stty -g` # save original terminal setting.
    read type           # read the type
    stty $stty_orig     # restore terminal setting.
    if [ -z "$type" ] 
    then
        type="new"
    elif [ "$type" = "e" ]
    then
        type='existing'
    else
        type='new'
    fi
else
    dprint "Commd line arg for type is: '$DEPLOY_TYPE'"
    if [[ "$DEPLOY_TYPE" = "'e'" || "$DEPLOY_TYPE" = "'existing'" ]]
    then
        type='existing'
    else
        type='new'
    fi
fi
echo ""
echo "--> Deployment type is $type ..."
echo ""

if [ -z "$DEPLOY_LOCATION" ]
then
    # Input location 
    echo -n "Enter location (e.g. eastus2): "
    stty_orig=`stty -g` # save original terminal setting.
    read location       # read the location
    stty $stty_orig     # restore terminal setting.
    if [ -z "$location" ] 
    then
        location="eastus2"
    fi
else
    # args passed in via CLI have quotes; xargs handily unqoutes them
    location="`echo $DEPLOY_LOCATION | xargs`" 
fi
export TF_VAR_LOCATION="$location"
echo ""
echo "--> Deployment in $location location ..."
echo ""

if [ -z "$DEPLOY_PREFIX" ]
then
    # Input prefix 
    echo -n "Enter prefix: "
    stty_orig=`stty -g` # save original terminal setting.
    read prefix         # read the prefix
    stty $stty_orig     # restore terminal setting.
    if [ -z "$prefix" ] 
    then
        prefix=""
    fi
else
    prefix="`echo $DEPLOY_PREFIX | xargs`"
fi
export TF_VAR_PREFIX="$prefix"
echo ""
if [ -z "$DEPLOY_PREFIX"]
then
    echo "--> No prefix being used ..."
else
    echo "--> Using prefix $prefix for all resources ..."
fi
echo ""

if [ -z "$DEPLOY_PASSWORD" ]
then
    # Input password 
    echo -n "Enter password: "
    stty_orig=`stty -g` # save original terminal setting.
    stty -echo          # turn-off echoing.
    read passwd         # read the password
    stty $stty_orig     # restore terminal setting.
    if [ -z "$passwd" ] 
    then
        passwd="1234qwerASDF"
    fi
    echo "Using default passwd '$passwd'"
else
    passwd="`echo $DEPLOY_PASSWORD | xargs`"
    echo ""
    echo "--> Using password found in env variable DEPLOY_PASSWORD ..."
    echo ""
fi
PASSWORD="$passwd"
DB_PASSWORD="$passwd"

if [ ! -z "$prefix" ]
then
    rg_cfg="${prefix}-RG"
fi

if [ "$type" = "new" ]
then
    # Input resource group
    echo -n "Enter resource group (<enter>=$rg_cfg): "
    stty_orig=`stty -g` # save original terminal setting.
    stty -echo          # turn-off echoing.
    read ans            # read the RG
    stty $stty_orig     # restore terminal setting.
    if [ -z "$ans" ] 
    then
        dprint "Using default RG"
    else
        rg_cfg="$ans"
    fi
    echo "Create resource group named '$rg_cfg'"

    # Input VNet/VPC name

else
    # Start collecting info from this subscription
    echo "Reading RGs..."
    rglist=''
    get_resource_groups
    echo "Reading VNets..."
    vnetlist=''
    get_vnets

    # List available RGs and select
    echo "Select RG:"
    my_selection=''
    get_selection "$rglist"
    rg_cfg="${my_selection}"

    # List available VNets/VPCs and select
    echo "Found VNets in ${location}:"
    echo "${vnetlist}"
    echo "Select VNet:"
    my_selection=''
    vnet_idx=''
    get_selection "$vnetlist"
    vnet_cfg="${my_selection}"
    vnet_count=`echo $((`echo "${vnet_json}" | jq '. | length'`-1))`
    for I in `seq 0 "${vnet_count}"`; do
        this_vnet=`echo "${vnet_json}" | jq -r --arg 'I' $I '.[$I | tonumber] | .name'`
        if [[ "${this_vnet}" == "${vnet_cfg}" ]]; then
            vnet_idx="${I}"
        fi
    done

    # Identify address space and enumerate subnets
    
fi

echo "Using RG '$rg_cfg'"
echo "Using VNet '$vnet_cfg' (index $vnet_idx)"