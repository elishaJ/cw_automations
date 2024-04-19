#!/bin/bash
# Purpose: Automate a task account-wide; perform an action on all running servers which requires root access
# Author: Elisha | Cloudways

clear
_bold=$(tput bold)
_underline=$(tput sgr 0 1)
_red=$(tput setaf 1)
_green=$(tput setaf 76)
_blue=$(tput setaf 38)
_reset=$(tput sgr0)

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
        get_email;
    fi
}
get_apiKey() {
    read -sp "Enter API key: " apikey
    echo " ";
    if [ -z $apikey ]; then
        get_apiKey;
    fi
}

# FETCH AND STORE ACCESS TOKEN
get_accesstoken() {
	_note "Retrieving Access Token"
	access_token=$(curl -s -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data '{"email" : "'$email'", "api_key" : "'$apikey'"}'  'https://api.cloudways.com/api/v1/oauth/access_token'  | jq -r '.access_token');
    sleep 5;
}

# FETCH SERVER LIST
get_serverList() {
	curl -s -X GET --header 'Accept: application/json' --header 'Authorization: Bearer '$access_token'' 'https://api.cloudways.com/api/v1/server' > $dir/server-list.txt;
}

# GET SERVER IPs
get_serverIP() {
	jq -r '.servers[] | select (.status == "'running'").public_ip' $dir/server-list.txt  > $dir/srvip.txt
	readarray -t srvIP < <(cat $dir/srvip.txt);
}

get_SSHusers() {
	jq -r '.servers[] | select (.status == "'running'").master_user' $dir/server-list.txt  > $dir/sshusers.txt
	readarray -t sshuser < <(cat $dir/sshusers.txt);
}

get_serverID() {
	jq -r '.servers[] | select (.status == "running").id' $dir/server-list.txt > $dir/srvIDs.txt;
	readarray -t srvID < <(cat $dir/srvIDs.txt);
}

get_email;
get_apiKey;
get_accesstoken;
get_serverList;
get_serverIP;
get_serverID;

# CONNECT TO EACH RUNNING SERVER AND PERFORM A TASK
do_task() {
for i in ${!srvIP[@]}; do
	sleep 5;
	ip=${srvIP[$i]}
	rsync -e "ssh -o StrictHostKeyChecking=no" $dir/blockedIPs systeam@$ip:/var/cw/systeam/;
	ssh -o StrictHostKeyChecking=no systeam@$ip 'bash -s' <<'EOF'

	####### Server level task
	sudo cp /etc/apache2/conf-enabled/security.conf /var/cw/systeam/security.conf
	sed -i 's/^ServerTokens .*/ServerTokens Prod/' /etc/apache2/conf-enabled/security.conf
		
	if apache2ctl configtest; then 
		service apache2 restart
		sudo rm /var/cw/systeam/security.conf;
	else
		sudo mv /var/cw/systeam/security.conf /etc/apache2/conf-enabled/security.conf
	fi	
	###############################################################################################
EOF
    _note "Exiting server ${srvIP[$i]}";
done;
}
do_task;

_note "Cleaning up files"
rm $dir/server-list.txt $dir/srvip.txt $dir/srvIDs.txt 
_success "Task completed"
exit;
