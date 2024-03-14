
## Git automation
* `workflow.yml` is a template to automate SSH task on Cloudways server after a Git pull.


<!-- ### Run Locally

Clone the project

```bash
  git clone https://github.com/elishaJ/cw_automations
```

Go to the project directory

```bash
  cd client/account_management/api/
```

Prerequisites

```bash
  sudo apt install jq
```

Run the script

```bash
  bash acc_api_task.sh
``` -->


### Usage
- Set up [Github Secrets](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions):
1. CLOUDWAYS_EMAIL (Cloudways primary account email)
2. [CLOUDWAYS_API_KEY](https://support.cloudways.com/en/articles/5136065-how-to-use-the-cloudways-api)


- Adjust environment variables:

```yaml

  env:
  app_id: <APP-ID>
  server_id: <SERVER-ID>
  branch_name: <branch-name>
  deploy_path: # not required for default webroot (public_html). To set deploy_path as a subfolder, define the folder name
```

- Modify step `ssh-task` in workflow to run custom commands on Cloudways server
```bash
- name: SSH task
  id: ssh-task
  run: | 
    master_user="${{ steps.ssh-auth-setup.outputs.master-user }}"
    sys_user="${{ steps.ssh-auth-setup.outputs.sys-user }}"
    public_ip="${{ steps.ssh-auth-setup.outputs.server-ip }}"
    key_path="${{ steps.ssh-auth-setup.outputs.key-path }}"
    ssh -i $key_path -o StrictHostKeyChecking=no $master_user@$public_ip 'bash -s' <<EOF
    # Task to done on app hosted on the server
    cd /home/master/applications/$sys_user/public_html/;
      # ADD YOUR SSH COMMANDS HERE
    EOF
```
