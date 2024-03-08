#!/bin/bash
clear
_bold=$(tput bold)
_underline=$(tput sgr 0 1)
_red=$(tput setaf 1)
_green=$(tput setaf 76)
_blue=$(tput setaf 38)
_reset=$(tput sgr0)

BASE_URL="https://api.cloudways.com/api/v1"
qwik_api="https://us-central1-cw-automations.cloudfunctions.net"
app_users=()
dir=$(pwd)
is_deleted=true

function _success()
{
	printf '%s✔ %s%s\n' "$_green" "$@" "$_reset"
}

function _error() {
    printf '%s✖ %s%s\n' "$_red" "$@" "$_reset"
}

function _note()
{
    printf '%s%s%sNote:%s %s%s%s\n' "$_underline" "$_bold" "$_blue" "$_reset" "$_blue" "$@" "$_reset"
}

get_email() {
    
    if [ -z $email ]; then
        read -p "Enter primary email: " email
        get_email
    fi
}

get_apiKey() {
    if [ -z $api_key ]; then
        read -sp "Enter API key: " api_key
        echo " "
        get_apiKey
    fi
}

get_user_credentials() {
    get_email
    get_apiKey
}

get_token() {
    _note "Retrieving access token"

    response=$(curl -s -X POST --location "$BASE_URL/oauth/access_token" \
        -w "%{http_code}" \
        --header 'Content-Type: application/x-www-form-urlencoded' \
        --data-urlencode 'email='$email'' \
        --data-urlencode 'api_key='$api_key'')

    http_code="${response: -3}"
    body="${response::-3}"

    if [ "$http_code" != "200" ]; then
        _error "Error: Failed to retrieve access token. Invalid credentials."
        sleep 3
        get_user_credentials
        get_token
    else
        # Parse the access token and set expiry time to 10 seconds
        access_token=$(echo "$body" | jq -r '.access_token')
        expires_in=$(echo "$body" | jq -r '.expires_in')
        expiry_time=$(( $(date +%s) + $expires_in ))
        _success "Access token generated."
    fi
}

check_token_validity() {
    current_time=$(date +%s)
    if [ "$current_time" -ge "$expiry_time" ]; then       
        validity="invalid"
        is_valid=false
        # echo "Token has expired"
        get_token
    else
        # echo "Token is valid"
        is_valid=true
    fi
}

get_app_user_ids() {
    _note "Fetch data from app_users.json "
    sleep 2
    if ! [ -f "$dir/app_users.json" ]; then
        _error "File app_users.json not found. Place JSON file containing app user IDs in current directory."
        exit

    else
        readarray -t app_ids < <(cat $dir/app_users.json | jq -r '.app_users[].app_id')
        readarray -t server_ids < <(cat $dir/app_users.json | jq -r '.app_users[].server_id')
        readarray -t app_cred_ids < <(cat $dir/app_users.json | jq -r '.app_users[].app_cred_id')
        readarray -t usernames < <(cat $dir/app_users.json | jq -r '.app_users[].username')
    fi
}

delete_app_users() {
    for i in "${!app_cred_ids[@]}"; do 
        app=${app_ids[i]}
        server=${server_ids[i]}
        app_cred_id=${app_cred_ids[i]}
        username=${usernames[i]}

        echo ""
        _note "Running for $server: $app"

        check_token_validity
        response=$(curl -s -X DELETE --location "$BASE_URL/app/creds/$app_cred_id" \
        --header 'Content-Type: application/x-www-form-urlencoded' \
        --header 'Accept: application/json' \
        --header 'Authorization: Bearer '$access_token'' \
        -d 'server_id='$server'&app_id='$app'')

        if [ "$response" == "[]" ]; then
            _success "User $username deleted."
        else
            retry_count=0
            while [[ "$(echo "$response" | jq -r '.message')" =~ ^"An operation is already in progress" ]] && [ $retry_count -lt $max_retries ]; do
                _note "An operation is already in progress on Server: $server"
                echo ""
                _note "Putting the script to sleep.."
                echo ""
                sleep 10
                _note "Trying again..."
                echo ""
                _note "Running for $server: $app"
                check_token_validity
                response=$(curl -s -X DELETE --location "$BASE_URL/app/creds/$app_cred_id" \
                    --header 'Content-Type: application/x-www-form-urlencoded' \
                    --header 'Accept: application/json' \
                    --header 'Authorization: Bearer '$access_token'' \
                    -d 'server_id='$server'&app_id='$app'&username='$username'')
                ((retry_count++))
            done
    
            if [[ "$(echo "$response" | jq -r '.message')" =~ ^"An operation is already in progress" ]]; then
                _error "Operation failed after $max_retries retries. Another operation is running on the server."
                _error "Failed to delete $username"
                echo "$server: $app" >> "$dir/deletion_error.txt"
                is_deleted=false
                continue
            else
                _error "Failed to delete $username."
                echo "$server: $app" >> "$dir/deletion_error.txt"
                echo "$response"
                is_deleted=false
            fi
        fi

        _note "Putting script to sleep to respect API rate limit."
        sleep 5
    done
    if [ "$is_deleted" == true ]; then
        _success "App users deleted for all project applications."
    else
        sleep 3
        echo ""
        _note "Failed deleted users exported in deletion_error.txt"
    fi
}
get_app_user_ids
get_user_credentials
get_token
delete_app_users