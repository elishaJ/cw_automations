
### Account-level automation
* `bulkatron.sh` is a template for automating account-wide operations. Facilitates SSH task automation for all applications on all running servers under the Cloudways account.


### Run Locally

Clone the project

```bash
  git clone https://github.com/elishaJ/cw_automations
```

Go to the project directory

```bash
  cd client/account_management/ssh/
```

Prerequisites

```bash
  sudo apt install jq
```

Run the script

```bash
  bash bulkatron.sh
```


## Usage
The tempate includes a `do_ssh_task` function which can be modified to run custom SSH commands across all running servers.

```bash
do_ssh_task() {
    for i in ${!users[@]}; do
        _note "Performing task on server ${ips[$i]}"
        ssh -i $key_path -o StrictHostKeyChecking=no ${users[$i]}@${ips[$i]} 'bash -s' <<'EOF'
            
        # Task to done on each app hosted on the server
        for app in $(ls -l /home/master/applications/ | awk '/^d/ {print $NF}'); do
            cd /home/master/applications/$app/public_html/;
            # Add your SSH commands here
            done;
EOF
...
```
