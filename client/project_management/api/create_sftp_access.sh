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
usercount=0
max_retries=10
is_created=true
dir=$(pwd)

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

get_app_password() {
    read -sp "Enter password for app users: " password
    echo " "
    if [ -z $password ]; then
        get_app_password
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
}

create_app_users() {
    for i in "${!server_ids[@]}"; do 
        app=${app_ids[i]}
        server=${server_ids[i]}
        db=${sys_users[i]}
        if [ "$usercount" -gt 0 ]; then
            username="$db-admin$usercount"
        else
            username="$db-admin"
        fi
        echo ""
        _note "Running for $server: $app"

        check_token_validity
        response="$(curl -s -X POST --location "$BASE_URL/app/creds" \
            --header 'Content-Type: application/x-www-form-urlencoded' \
            --header 'Accept: application/json' \
            --header 'Authorization: Bearer '$access_token'' \
            -d 'server_id='$server'&app_id='$app'&username='$username'&password='$password'')"

        # Handle case where operation is already in progress
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
            response="$(curl -X POST --location "$BASE_URL/app/creds" \
                --header 'Content-Type: application/x-www-form-urlencoded' \
                --header 'Accept: application/json' \
                --header 'Authorization: Bearer '$access_token'' \
                -d 'server_id='$server'&app_id='$app'&username='$username'&password='$password'')"
            ((retry_count++))
        done

        # Check if response contains status field
        if [[ "$(echo "$response" | jq -r '.status')" == "true" ]]; then
            _success "User $username created successfully."

            # Extract app_cred_id from response
            app_cred_id=$(echo "$response" | jq -r '.app_cred_id')

            # Append app user object to array
            app_users+=( "{\"app_id\": \"$app\", \"server_id\": \"$server\", \"username\": \"$username\", \"app_cred_id\": \"$app_cred_id\"}" )
        else
            # Check if response contains password policy validation error
            if [[ "$(echo "$response" | jq -r '.password[0].code')" == "passwordpolicy" ]]; then
                # _note "Password policy validation error found. Invoking get_app_password function."
                _error "Failed to create user $username"
                echo "$response"
                sleep 2
                _note "Password policy validation error found. Provide a stronger password"
                sleep 2
                get_app_password

                # Fetch new password and rerun create_app_users with the new password
                create_app_users 
                return  # Exit the loop
            
            elif [[ "$(echo "$response" | jq -r '.message')" == "username already exists" ]]; then
                _error "Failed to create user $username"
                echo "$response"
                # echo "Changing app username."
                let "usercount=usercount+1"
                sleep 2
                _note "Changing username suffix to admin$usercount"
                sleep 2
                create_app_users
                return

            elif [[ "$(echo "$response" | jq -r '.message')" =~ ^"An operation is already in progress" ]]; then
                _error "Operation failed after $max_retries retries. Another operation is running on the server."
                _error "Failed to create $username"
                echo "$server: $app" >> "$dir/creation_error.txt"
                is_creation=false
                continue
            else
                # Print the message from the response directly
                _error "Failed to create user $username"
                echo "$response"
                echo "$server: $app" >> "$dir/creation_error.txt"
                is_created=false
                return
            fi
        fi

        _note "Putting script to sleep to respect API rate limit."
        sleep 5
    done

    if [ "$is_created" == true ]; then
        _success "App users created for all project applications."
        export_app_users
    else
        sleep 3
        echo ""
        _note "Failed user creation exported in creation_error.txt"
    fi
}

export_app_users(){
    # Export app users in JSON format and write it to the file
    printf '{"app_users":[%s]}\n' "$(IFS=','; echo "${app_users[*]}")" > app_users.json
    _note "Users exported in app_users.json file."
}

get_user_credentials
get_token
get_project_id
verify_project_id
get_project_apps
get_app_password
create_app_users