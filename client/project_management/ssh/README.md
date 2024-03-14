
### Account-level automation
* `bash_projektor.sh` is a template for automating project-wide operations. Facilitates SSH task automation for all applications under a Cloudways project.


### Run Locally

Clone the project

```bash
  git clone https://github.com/elishaJ/cw_automations
```

Go to the project directory

```bash
  cd client/project_management/api/
```

Prerequisites

```bash
  sudo apt install jq
```

Run the script

```bash
  bash bash_projektor.sh
```


## Usage
The tempate includes a `do_ssh_task` function which can be modified to run custom SSH commands across all project applications.

```bash
do_ssh_task() {

    # Perform SSH task for each project app
    for i in "${!server_ips[@]}"; do
        _note "Performing task on application: ${sys_users[$i]}"
        ssh -i $key_path -o StrictHostKeyChecking=no ${master_users[$i]}@${server_ips[$i]} 'bash -s' <<EOF
            app=${sys_users[$i]}
            cd /home/master/applications/\$app/public_html/
            # Add your commands here
EOF
...
```
