<div align="center">
  <img src="https://user-images.githubusercontent.com/74038190/212748842-9fcbad5b-6173-4175-8a61-521f3dbb7514.gif" alt="MasterHead">
</div>

<h1 align="center">Cloudways Automations</h1>

Welcome to the Cloudways Automations repository! This repository contains automation scripts tailored to streamline various aspects of managing Cloudways accounts and projects.


### Folders
**Client**: 
The main "Client" folder includes automation scripts for account and project management tasks on Cloudways, as well as post-deployment automation for seamless application maintenance.

**Server**:
The "Server" folder comprises essential tools and scripts aimed at enhancing server management efficiency.

### Roadmap

- [x]  Account-wide SSH task automation (all apps + all running servers)
- [x]  Account-wide UI task automation using Cloudways API  
- [x]  Project-wide SSH task automation (all apps + all running servers)
- [x]  Project-wide UI task automation using Cloudways API
- [x]  Post-Git Deployment automation
### Layout

```tree
├── client
│   ├── account_management
│   │   ├── api
│   │   |   └── acc_api_task.sh
│   │   └── ssh
│   │       └── bulkatron.sh
│   ├── post_deployment
│   │   └── git
│   │       └── workflow.yaml
│   └── project_management
│       ├── api
│       |   ├── api_projektenator.sh
│       |   ├── create_sftp_access.sh
│       |   └── remove_sftp_access.sh
│       └── ssh
│           └── bash_projektor.sh
├── server
│   └── administration
│       ├── apm.sh
│       └── myvars
├── .gitignore
└── README.md

```

A brief description of the layout:

* `client` has 3 folders. Please see the folder description for details.
* `account_management` contains API and SSH folders which contain automation scripts for respective tasks at the account-level.
* `acc_api_task.sh` is the automation to script to perform Platform UI task on all running servers+applications.
* `bulkatron.sh` is for automating account-wide SSH operations.
* `post_deployment` holds scripts for post-deployment tasks.
* `git` folder holds Git-related automations.
* `workflow.yaml` Github action to automate SSH task on Cloudways server after a Git pull.
* `project_management` contains API and SSH folders which hold automation scripts for respective tasks at the project-level.
* `api_projektenator.sh` is a template for project management via Cloudways API. Facilitates API task automation for all applications in a project.
* `create_sftp_access.sh` is for creating SFTP access for projects applications.
* `remove_sftp_access.sh` removes SFTP users created by `create_sftp_access.sh`
* `bash_projektor.sh` is a template for project management via SSH. Facilitates SSH task automation for all applications in a project.
* `server` folder for server administration tasks.
* `apm.sh` is a script for debugging server load and performance issues.
* `myvars` is a collection of functions and aliases to improve efficiency for daily administrative tasks. 
* `.gitignore` for excluding specific files and directories.
* `README.md` Project readme file.

### Built with

- Bash
- YAML
###  Skills
- Bash scripting
- Github Actions

### Badges

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)



### Feedback

If you have any feedback, please reach out to me at elisha.jamil@gmail.com
