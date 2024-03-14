
## Account-level automation
* `api_projektenator.sh` is a template for project management via Cloudways API. Facilitates API task automation for all applications under a Cloudways project.

* `create_sftp_access.sh` allows account admins to create SFTP users that provide access to projects applications to team members/developers. 
* `remove_sftp_access.sh` removes SFTP users created by `create_sftp_access.sh`

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
  bash api_projektenator.sh
```


### Usage
The tempate enables Cron Optimizer for all WordPress applications associated with a Cloudways project. The script can be modified to run any UI task by changing the API endpoint and request parameters

```bash
BASE_URL="https://api.cloudways.com/api/v1"
task_endpoint="app/manage/cron_setting" # Change this endpoint
```
To view API endpoints and required parameters, refer to Cloudways API documentation: https://developers.cloudways.com/docs/