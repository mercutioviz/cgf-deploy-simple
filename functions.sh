## Cloud Installer Helper Functions

dprint() {
    if [ "$DEBUG" == 'true' ]
    then
        echo "$@" 1>&2
    fi
}

get_selection() {
    if [ -z "$@" ]
    then
        dprint "Call to get_selection function w/o an argument; no selection set"
    else
        #
        select my_selection in `echo $@`;
        do 
            echo "You chose '${my_selection}' - press <enter> to accept, any other key select again"
            stty_orig=`stty -g` # save original terminal setting.
            stty -echo          # turn-off echoing.
            read ans            # read the RG
            stty $stty_orig     # restore terminal setting.
            if [ -z "$ans" ] 
            then
                break 
            else
                echo ""
            fi
        done
    fi
}

cloud_cli_available() {
    # return true if CLI stuff is found
    case "$1" in
        Azure|azure|Az|AZ|az)
            # check for Azure CLI
            myaz=`az --version | grep azure-cli`
            if [ ! -z "$myaz" ]
            then
                CLOUD_FOUND="True"
                dprint "Found Azure ($myaz)"
            fi
            ;;
        GCP|gcp)
            # check for GCP CLI
            ;;
        AWS|aws)
            # check for AWS CLI
            ;;
    esac

    return
}

function get_vms() {
    #
    return 0
}

function get_resource_groups() {
    #
    case "$CLOUD" in
    Azure)
        # Get Azure RGs
        rglist=`/usr/bin/az group list --query "[?location=='${location}']" | json_pp | jq -r '.[] | .name'`
        ;;
    AWS)
        # Get AWS RGs

        ;;
    GCP)
        # Get GCP RGs

        ;;
    (*) break;;
    esac

    return 0
}

function get_vnets() {
    #
    vnet_json=`az network vnet list --query "[?location=='${location}']" | json_pp`
    #dprint "VNet JSON data: ${vnet_json}"
    vnetlist=`echo "${vnet_json}" | jq -r '.[] | .name'`
    dprint "VNet list: ${vnet_list}"
    vnet_count=`echo "${vnet_json}" | jq -r '. | length'`
    
    return 0
}

function get_pips() {
    #
    return 0
}

function get_lbs() {
    #
    return 0
}

function get_route_tables() {
    #
    return 0
}

function get_routes() {
    #
    return 0
}

function get_available_cpus() {
    # How many vCPUs available to deploy in this region
    return 1
}

function get_regions() {
    #
    return 0
}
