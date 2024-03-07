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
    echo " "
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
    response=$(curl -s -X POST --location "$qwik_api/token" \
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
        access_token=$(echo "$body" | jq -r '.[]')
        _success "Access token generated."
    fi
}

get_apps() {
    _note "Fetching app info"
    apps_response=$(curl -s --location ''$qwik_api'/apps?project_id='$project_id'' \
        --header 'Authorization: Bearer '$access_token'')

    app_ids=$(echo "$apps_response" | jq -r '.apps[].id')
    server_ids=$(echo "$apps_response" | jq -r '.apps[].server_id')
    sys_users=$(echo "$apps_response" | jq -r '.apps[].sys_user')

    IFS=$'\n' read -d '' -r -a app_ids_array <<<"$app_ids"
    IFS=$'\n' read -d '' -r -a server_ids_array <<<"$server_ids"
    IFS=$'\n' read -d '' -r -a sys_users_array <<<"$sys_users"
}

create_app_users() {
    for i in "${!server_ids_array[@]}"; do 
        app=${app_ids_array[i]}
        server=${server_ids_array[i]}
        db=${sys_users_array[i]}
        username="$db-appadmin"
        echo ""
        _note "Running for $server: $app"

        response="$(curl -s -X POST --location "$BASE_URL/app/creds" \
            --header 'Content-Type: application/x-www-form-urlencoded' \
            --header 'Accept: application/json' \
            --header 'Authorization: Bearer '$access_token'' \
            -d 'server_id='$server'&app_id='$app'&username='$username'&password='$password'')"

        # Check if response contains status field
        if [[ "$(echo "$response" | jq -r '.status')" == "true" ]]; then
            _success "App user created successfully."

            # Extract app_cred_id from response
            app_cred_id=$(echo "$response" | jq -r '.app_cred_id')

            # Append app user object to array
            app_users+=( "{\"app_id\": \"$app\", \"server_id\": \"$server\", \"app_cred_id\": \"$app_cred_id\"}" )
        else
            # Check if response contains password policy validation error
            if [[ "$(echo "$response" | jq -r '.password[0].code')" == "passwordpolicy" ]]; then
                # _note "Password policy validation error found. Invoking get_app_password function."
                _error "Failed to create app user"
                echo "$response"
                sleep 2
                _note "Password policy validation error found. Provide a stronger password"
                sleep 2
                get_app_password

                # Fetch new password and rerun create_app_users with the new password
                create_app_users 
                return  # Exit the loop after rerunning create_app_users with the new password
            else
                # Print the message from the response directly
                _error "Failed to create app user"
                echo "$response"
                return
                # Handle other error conditions as per your requirements
            fi
        fi

        # Handle case where operation is already in progress
        while [[ "$(echo "$response" | jq -r '.message')" =~ ^"An operation is already in progress" ]]; do
            _note "An operation is already in progress on Server: $server"
            echo ""
            _note "Putting the script to sleep.."
            echo ""
            sleep 10
            _note "Trying again..."
            echo ""
            _note "Running for $server: $app"
            response="$(curl -X POST --location "$BASE_URL/app/creds" \
                --header 'Content-Type: application/x-www-form-urlencoded' \
                --header 'Accept: application/json' \
                --header 'Authorization: Bearer '$access_token'' \
                -d 'server_id='$server'&app_id='$app'&username='$username'&password='$password'')"
        done

        _note "Putting script to sleep to respect API rate limit."
        sleep 5
    _success "App users created for all project applications."
    export_app_users
    done
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
get_app_password
get_apps
create_app_users