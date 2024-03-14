
## Account-level automation
* `acc_api_task.sh` is a template for account management via Cloudways API. Facilitates API task automation for all applications on all running servers under the Cloudways account.


### Run Locally

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
```


### Usage
The tempate enables Cron Optimizer for all WordPress applications hosted on the account. The script can be modified to run any UI task by changing the API endpoint and request parameters

```bash
BASE_URL="https://api.cloudways.com/api/v1"
task_endpoint="app/manage/cron_setting" # Change this endpoint
```
To view API endpoints and required parameters, refer to Cloudways API documentation: https://developers.cloudways.com/docs/