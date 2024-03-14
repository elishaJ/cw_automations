#!/bin/bash
# Author: Elisha
# Purpose: Template for project management via SSH session. Perform SSH task for all applications in a project.
clear

# Variable declarations
_bold=$(tput bold)
_underline=$(tput sgr 0 1)
_red=$(tput setaf 1)
_green=$(tput setaf 76)
_blue=$(tput setaf 38)
_reset=$(tput sgr0)
dir=$(pwd)
key_path="$HOME/.ssh/bulk_project_ops"
BASE_URL="https://api.cloudways.com/api/v1"
qwik_api="https://us-central1-cw-automations.cloudfunctions.net"

# Function definitions
function _note() {
    printf '%s%s%sNote:%s %s%s%s\n' "$_underline" "$_bold" "$_blue" "$_reset" "$_blue" "$@" "$_reset"
}

function _success() {
    printf '%s✔ %s%s\n' "$_green" "$@" "$_reset"
}

function _error() {
    printf '%s✖ %s%s\n' "$_red" "$@" "$_reset"
}

get_email() {
    read -p "Enter primary email: " email
    if [ -z $email ]; then
        get_email
    fi
}

get_apiKey() {
    read -sp "Enter API key: " api_key
    echo " "
    if [ -z $api_key ]; then
        get_apiKey
    fi
}

get_project_id() {
    read -p "Enter project ID: " project_id
    if [ -z $project_id ]; then
        get_project_id
    fi
}

get_user_credentials() {
    get_email
    get_apiKey
}

# Fetch access token
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
    fi
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

# Generate an SSH key for passwordless connection to Cloudways server
generate_SSH_key() {
    _note "Creating SSH key"
    ssh-keygen -b 2048 -t rsa -f "$key_path" -q -N "" #> /dev/null
    pub_key=$(<"$key_path.pub")
}

setup_SSH_keys() {
    check_token_validity
    _note "Uploading SSH keys on Cloudways servers."
    task_id=($(curl -s --location "$qwik_api/auth" \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    --header 'Authorization: Bearer '$access_token'' \
    --data-urlencode 'pub_key='"$pub_key" \
    --data-urlencode 'email='$email'' \
    --data-urlencode 'project_id='$project_id'' \
    | jq -r '.task_id'))
    if [ -z task_id ]; then
        _error "SSH keys set up failed."
        generate_SSH_key
        setup_SSH_keys
    else
        _success "SSH key setup completed successfully"
        echo "task_id: $task_id" >> $dir/task_id.txt 
    fi
    
}

# Fetch app IDs, server IDs, and sys users
get_project_apps() {
    _note "Fetching app info"
    apps_response=$(curl -s --location ''$qwik_api'/apps?project_id='$project_id'' \
        --header 'Authorization: Bearer '$access_token'')

    readarray -t app_ids < <(echo "$apps_response" | jq -r '.apps[].app_id')
    readarray -t server_ips < <(echo "$apps_response" | jq -r '.apps[].server_ip')
    readarray -t sys_users < <(echo "$apps_response" | jq -r '.apps[].sys_user')
    readarray -t master_users < <(echo "$apps_response" | jq -r '.apps[].master_user')
}

do_ssh_task() {

    # Perform SSH task for each project app
    for i in "${!server_ips[@]}"; do
        _note "Performing task on application: ${sys_users[$i]}"
        ssh -i $key_path -o StrictHostKeyChecking=no ${master_users[$i]}@${server_ips[$i]} 'bash -s' <<EOF
            app=${sys_users[$i]}
            cd /home/master/applications/\$app/public_html/
            touch projektenator.txt
EOF
    done
    echo " "
    _note "Task ID = $task_id"
    _success "Task executed on all project applications"
}

delete_ssh_keys(){
    check_token_validity
    _note "Deleting SSH keys from servers"
    curl --location --request DELETE "$qwik_api/cleanup" \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    --header 'Authorization: Bearer '$access_token'' \
    --data-urlencode 'task_id='$task_id''
    _note "Deleting local SSH key"
    rm -f $key_path*
}

get_user_credentials
get_token
get_project_id
verify_project_id
get_project_apps
generate_SSH_key
setup_SSH_keys
do_ssh_task
delete_ssh_keys