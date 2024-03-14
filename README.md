
# Cloudways Automations

Welcome to the Cloudways Automations repository! This repository contains automation scripts tailored to streamline various aspects of managing Cloudways accounts and projects.


### Folders
**Client**: 
The main "Client" folder includes automation scripts for account and project management tasks on Cloudways, as well as post-deployment automation for seamless application maintenance.

- *Account Management*:
Within this folder, you'll find automation scripts streamline account-wide tasks on Cloudways. These scripts allow account administrators to efficiently manage various aspects of their Cloudways account and perform SSH/Platform tasks through a single script on all running servers.

- *Project Management*:
Inside this folder, you'll find scripts tailored to automate various project management tasks. These scripts empower account administrators to effortlessly manage team member access across all applications within their projects. Additionally, they streamline the execution of SSH/Platform tasks through a single script, effectively saving valuable time.

- *Post Deployment*:
The Post Deployment folder contains Github workflow YAML file for executing custom SSH commands on servers following a successful Git pull. This scripts enable users to automate post-deployment tasks, such as database migrations, cache clearing, or any other actions required to ensure the smooth functioning of applications after code updates.

**Server**
The "Server" folder comprises essential tools and scripts aimed at enhancing server management efficiency.
- *Administration*:
Includes an APM (Application Performance Monitoring) script tailored for debugging server load and performance issues, providing invaluable insights for optimization. The myvars file is collection of functions and aliases to streamline common server administration tasks, empowering administrators to execute operations swiftly and effectively.
### Roadmap

- [x]  Account-wide SSH task automation (all apps + all running servers)
- [x]  Account-wide Platform task automation using Cloudways API  
- [x]  Project-wide SSH task automation (all apps + all running servers)
- [x] Project-wide platform task using Cloudways API
- [x] Post Git Deployment automation 
### Layout

```tree
├── client
│   ├── account_management
│   │   ├── api
│   │       └── acc_api_task.sh
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



## Feedback

If you have any feedback, please reach out to me at elisha.jamil@gmail.com

