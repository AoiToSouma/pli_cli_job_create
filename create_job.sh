#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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
    read -p "Inpute Oracle Contract Address : " oca

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
    plugin jobs create "${created_toml}"
    echo -e "${NC}"
done
