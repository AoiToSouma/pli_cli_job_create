#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

sudo -l > /dev/null 2>&1

curdir=$(echo `pwd`)
workdir=$(cd $(dirname $0); pwd)
if [ "${curdir}" != "${workdir}" ]; then
    echo "[INFO]change directory ${workdir}"
    cd ${workdir}
fi 

source .api

while true; do
    echo "Select API:"
    for selection in "${selections[@]}"
    do
        echo "$selection"
    done
    echo "q.  Exit "
    read -p "Choice : " choice
    if [ "${choice}" = "q" ]; then
        echo "Exiting..."
        exit 0
    elif [ "${selections[choice]}" = "" ]; then
        echo -e "${RED}Invalid choice. Please try again.${NC}"
        continue
    else
        echo -e "${GREEN}You selected ${selections[$choice]}"
        echo -e "${explanations[$choice]}${NC}"
    fi
    read -p "Input Base Currency : " base_currency
    read -p "Input Target Currency : " target_currency
    read -p "Input Job Name : " job_name
    echo -e "${GREEN}Oracle Contract Address's 'xdc' prefix is automatically converted to '0x'.${NC}"
    read -p "Input Oracle Contract Address : " oca

    oca="$(echo ${oca} | sed '/^$/d;/^\\s*$/d;s/^xdc/0x/g')"

    url=$(echo ${urls[$choice]} | sed 's/[][^$*?+!/\\()&|'\''"]/\\&/g')
    path=${paths[$choice]}
    api_key=${api_keys[$choice]}
    option=$(echo ${options[$choice]} | sed 's/[][^$*?+!/\\()&|'\''"]/\\&/g')

    if [ ! -d "created-toml" ]; then
        echo "[INFO]CREATE DIRECTORY : created-toml"
        mkdir created-toml
    fi
    created_toml="created-toml/${job_name}.toml"
    cp sample.toml "${created_toml}"
    sed -i 's/NEW_JOB_NAME/'"${job_name}"'/g' "${created_toml}"
    sed -i 's/YOUR_ORACLE_ADDRESS/'"${oca}"'/g' "${created_toml}"
    sed -i 's/API_URL/'"${url}"'/g' "${created_toml}"
    sed -i 's/API_PATH/'"${path}"'/g' "${created_toml}"
    sed -i 's/BASE_CURRENCY/'"${base_currency}"'/g' "${created_toml}"
    sed -i 's/TARGET_CURRENCY/'"${target_currency}"'/g' "${created_toml}"
    sed -i 's/OPTION/'"${option}"'/g' "${created_toml}"
    sed -i 's/YOUR_API_KEY/'"${api_key}"'/g' "${created_toml}"

    echo -e "${GREEN}plugin login"
    plugin admin login -f ~/pluginV2/apicredentials.txt
    echo -e "${NC}"
    plugin jobs create "${created_toml}"
    rc=$?
    echo -e "${NC}"
    if [ $rc != 0 ]; then
        echo  -e "${RED}[ERROR] Plugin JOBS creation encoutered issues${NC}"
        rm -f created-toml/${job_name}.toml
        exit
    else
        ext_job_id_raw="$(sudo -u postgres -i psql -d plugin_mainnet_db -t -c "SELECT external_job_id FROM jobs WHERE name = '$job_name';")"
        ext_job_id=$(echo $ext_job_id_raw | tr -d \-)

        num_job_name=$(( ${#job_name}+9 ))
        if [ $num_job_name -ge 25 ]; then
            oca_prefix="$(echo "$(printf "%-${num_job_name}s\n" "Oracle Contract Address is")" " :")"
            jobname_prefix="$(echo "JOB $job_name ID is :")"
        else
            oca_prefix="$(echo "Oracle Contract Address is :")"
            jobname_prefix="$(echo "$(printf "%-25s\n" "JOB $job_name ID is")" " :")"
        fi
        echo -e "${GREEN}"
        echo
        echo -e "       Local node job id - Copy to your Solidity script"
        echo -e "================================================================="
        echo -e
        echo -e "$oca_prefix$oca"
        echo -e "$jobname_prefix$ext_job_id ${NC}"
    fi
    echo
done
