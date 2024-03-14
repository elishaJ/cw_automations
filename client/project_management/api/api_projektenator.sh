#!/bin/bash
# Author: Elisha
# Purpose: Template for project management via Cloudways API. Perform API task for all applications in a project.
clear

_bold=$(tput bold)
_underline=$(tput sgr 0 1)
_red=$(tput setaf 1)
_green=$(tput setaf 76)
_blue=$(tput setaf 38)
_reset=$(tput sgr0)

BASE_URL="https://api.cloudways.com/api/v1"
task_endpoint="app/manage/cron_setting"
qwik_api="https://us-central1-cw-automations.cloudfunctions.net"
app_users=()
usercount=0
max_retries=10
is_created=true
dir=$(pwd)

function _success() {
    printf '%s✔ %s%s\n' "$_green" "$@" "$_reset"
}

function _error() {
    printf '%s✖ %s%s\n' "$_red" "$@" "$_reset"
}

function _note() {
    printf '%s%s%sNote:%s %s%s%s\n' "$_underline" "$_bold" "$_blue" "$_reset" "$_blue" "$@" "$_reset"
}

get_email() {
    read -p "Enter primary email: " email
    if [ -z "$email" ]; then
        get_email
    fi
}

get_apiKey() {
    read -sp "Enter API key: " api_key
    echo " "
    if [ -z "$api_key" ]; then
        get_apiKey
    fi
}

get_app_password() {
    read -sp "Enter password for app users: " password
    echo " "
    if [ -z "$password" ]; then
        get_app_password
    fi
}

get_project_id() {
    read -p "Enter project ID: " project_id
    if [ -z "$project_id" ]; then
        get_project_id
    fi
}

get_user_credentials() {
    get_email
    get_apiKey
}

verify_project_id() {
    _note "Verifying project ID"
    
    # Fetch all project IDs
    response=$(curl -s -X GET --location "$BASE_URL/project" \
        --header 'Authorization: Bearer '$access_token'' \
        --header 'Accept: application/json')

    # Check if the project_id exists in the list of projects
    if jq -e ".projects[] | select(.id == \"$project_id\")" <<< "$response" > /dev/null; then
        _success "Project ID verified."
    else
        _error "Project ID $project_id does not exist."
        get_project_id
        verify_project_id
    fi
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

get_project_apps() {
    _note "Fetching app info"
    apps_response=$(curl -s --location ''$qwik_api'/apps?project_id='$project_id'' \
        --header 'Authorization: Bearer '$access_token'')

    readarray -t app_ids < <(echo "$apps_response" | jq -r '.apps[].id')
    readarray -t server_ids < <(echo "$apps_response" | jq -r '.apps[].server_id')
    readarray -t sys_users < <(echo "$apps_response" | jq -r '.apps[].sys_user')
    readarray -t app_types < <(echo "$apps_response" | jq -r '.apps[].application')
}

enable_cron_optimizer() {
    _note "Enabling cron optimizer for project apps"

    for i in "${!app_ids[@]}"; do 
        app_id="${app_ids[i]}"
        server_id="${server_ids[i]}"
        app_type="${app_types[i]}"

        # Check if the app is wordpress, woocommerce, or wordpressmu
        if [[ "$app_type" == "wordpress" || "$app_type" == "woocommerce" || "$app_type" == "wordpressmu" ]]; then
            _note "Running on app ID: $app_id"

            check_token_validity
            
            response=$(curl -s -X POST --header 'Content-Type: application/x-www-form-urlencoded' --header 'Accept: application/json' --header 'Authorization: Bearer '$access_token'' \
                -d 'server_id='$server_id'&app_id='$app_id'&status=enable' "$BASE_URL/$task_endpoint")

            operation_id=$(echo "$response" | jq -r '.operation_id')

            # Handle case where operation is already in progress
            retry_count=0
            while [[ "$(echo "$response" | jq -r '.message')" =~ ^"An operation is already in progress" ]] && [ $retry_count -lt $max_retries ]; do
                _note "An operation is already in progress for app ID: $app_id"
                echo ""
                _note "Putting the script to sleep.."
                echo ""
                sleep 10
                _note "Trying again..."
                echo ""
                _note "Enabling cron optimizer for app ID: $app_id"
                check_token_validity
                response=$(curl -s -X POST --header 'Content-Type: application/x-www-form-urlencoded' --header 'Accept: application/json' --header 'Authorization: Bearer '$access_token'' \
                    -d 'server_id='$server_id'&app_id='$app_id'&status=enable' "$BASE_URL/$task_endpoint")
                ((retry_count++))
            done

            # Wait for the operation to complete
            while true; do
                operation_response=$(curl -s "$BASE_URL/operation/$operation_id" --header 'Authorization: Bearer '$access_token'')
                operation_status=$(echo $operation_response | jq -r '.operation.status')
                is_completed=$(echo $operation_response | jq -r '.operation.is_completed')
                if [ "$operation_status" == "Operation completed" ]; then
                    _success "Cron optimizer enabled for app ID: $app_id"
                    break
                fi
                if [ "$is_completed" == "-1" ]; then
                    operation_message=$(curl -s "$BASE_URL/operation/$operation_id" --header 'Authorization: Bearer '$access_token'' | jq -r '.operation.message')
                    _error "Operation failed for app ID: $app_id. Error message: $operation_message"
                    echo $app_id > $dir/failed_apps.txt
                    break
                fi
                sleep 5
            done
        else
            _note "Skipping app ID: $app_id as it's not a wordpress application"
        fi
    done

    _success "Cron optimizer enabled for all eligible project apps."
}

get_user_credentials
get_token
get_project_id
verify_project_id
get_project_apps
enable_cron_optimizer