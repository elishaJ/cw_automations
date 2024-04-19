#!/bin/bash
# Purpose: Block a list of IPs via Nginx on all running servers under account
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
if [ -z $email ]; then
	read -p "Enter primary email: " email
	get_email;
fi
}
get_apiKey() {
if [ -z $apikey ]; then
        read -sp "Enter API key: " apikey
	echo " ";
	get_apiKey;
fi
}

if ! [ -f "$dir/blacklist" ]; then
        _error "File blacklist not found. Place txt file containing bad IPs in current directory."
        exit
fi

get_email;
get_apiKey;

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

get_accesstoken;
get_serverList;
get_serverIP;

# CONNECT TO EACH RUNNING SERVER AND PERFORM A TASK
do_task() {
for i in ${!srvIP[@]}; do
	sleep 5;
	ip=${srvIP[$i]}
	rsync -e "ssh -o StrictHostKeyChecking=no" $dir/blacklist systeam@$ip:/var/cw/systeam/;
	ssh -o StrictHostKeyChecking=no systeam@$ip 'bash -s' <<'EOF'
		
	####### Server level task
	sudo cp /etc/nginx/additional_server_conf /var/cw/systeam/additional_server_conf;
	sudo cp /etc/nginx/conf.d/ngx_maps_header.conf /var/cw/systeam/ngx_maps_header.conf;
	sudo chown root:root /var/cw/systeam/blacklist;

	while IFS= read -r ip; do
    # Append IP to blacklist
        # if ! sudo grep -qF "$ip" /etc/nginx/additional_server_conf; then
		if ! sudo grep -qF "$ip" /etc/nginx/blacklist; then
			echo "$ip 1;" | sudo tee -a /etc/nginx/blacklist > /dev/null;
        fi
	done < /var/cw/systeam/blacklist
	
	if ! sudo grep -qF "custom-blacklist" /etc/nginx/additional_server_conf; then
        echo -e "\n# Block IPs; custom-blacklist\nif (\$allowed != 0){\n\treturn 403;\n}" | sudo tee -a /etc/nginx/additional_server_conf > /dev/null;
        echo -e "\nmap \$realip_remote_addr \$allowed {\n        default 0;\n        include \"/etc/nginx/blacklist\";\n}" | sudo tee -a /etc/nginx/conf.d/ngx_maps_header.conf > /dev/null;
	fi

	if sudo nginx -t; then 
		sudo /etc/init.d/nginx restart;
		sudo rm /var/cw/systeam/additional_server_conf /var/cw/systeam/ngx_maps_header.conf;
		echo -e "IPs blocked successfully\n"
	else
		sudo mv /var/cw/systeam/additional_server_conf /etc/nginx/additional_server_conf;
		sudo mv /var/cw/systeam/ngx_maps_header.conf /etc/nginx/conf.d/ngx_maps_header.conf;
        sudo rm /etc/nginx/blacklist
	fi	
	###############################################################################################
EOF
    _note "Exiting server ${srvIP[$i]}";
done;
}
do_task;

_note "Cleaning up files"
rm $dir/server-list.txt $dir/srvip.txt
_success "Task completed"
exit;
