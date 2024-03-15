
# Post Git Deployment automation
* `workflow.yml` is a template to automate SSH task on Cloudways server after a Git pull.

## Usage

### Pre-requisites
Create a workflow `.yml` file in your repository's .`github/workflows` directory. An example workflow is available [here](https://github.com/elishaJ/cw_automations/blob/main/client/post_deployment/git/workflow.yml). For more information, refer to the GitHub Help Documentation for creating a [workflow file](https://docs.github.com/en/actions/using-workflows).

#### Github Secrets
* `CLOUDWAYS_EMAIL` Cloudways primary account email
* `CLOUDWAYS_API_KEY` API Key generated on [Cloudways Platform API](https://support.cloudways.com/en/articles/5136065-how-to-use-the-cloudways-api) Section

#### Environment Variables
* `app_id` Numeric ID of the application.
* `server_id` Numeric ID of the server.
* `branch_name` Git branch name.
* `deploy_path` (optional) To set deploy_path other than public_html, define the folder name.

#### SSH task automation
- Modify step `ssh-task` in workflow to run custom commands on Cloudways application after pulling changes from repository.
```yaml
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
    ...
```
