# Trade Flows Analysis Pipeline
## Introduction
This repository contains a data pipeline for ingesting and analysing trade data contained in the BACI database. It has been created for the purpose of being submitted as project for the [Data Engineering Zoomcamp](https://github.com/DataTalksClub/data-engineering-zoomcamp)


## Requirements
- An account on Google Cloud Platform (GCP) with credits

## Setup walkthrough
In case you would like to run the data pipeline, follow the steps described below.
1. On GCP, create a new project
2. Create a service account and assign the "Storage Admin", "BigQuery Admin" and "Compute Admin" roles to it
3. Create a JSON key for that account

This project was setup and run from a GCP virtual machine. In case you would like to also setup a virtual machine and use it to execute the pipeline, follow the instructions below:
1. To be able to connect to the virtual machine, you first need to generate an SSH key. Follow the instructions provided on this [Google Cloud documentation page](https://cloud.google.com/compute/docs/connect/create-ssh-keys#create_an_ssh_key_pair) to generate one. A public key will be created as well.
2. On GCP, enable the Compute Engine API and go to the Metadata setting page in Compute Engine
3. Select the SSH Keys tab, add the ***public*** SSH key that was generated and save it
4. Go to VM instances and create a VM instance. Select a region located near your location. For the machine type, use the e2-standard-2 (2 vCPU, 1 core, 8 GB memory). Click on the OS and storage tab, and change the operating system to Ubuntu 24.04 LTS. Set the disk size set to 20 GB. Click Create to create the instance.
5. Connect to the VM


6. Install miniconda

```
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
```

```
bash Miniconda3-latest-Linux-x86_64.sh
```

Answer yes when prompted with "Do you wish to update your shell profile to automatically initialize conda?"

Then execute the following command to check that the base environment is activated automatically when opening the shell on the VM.
```
source .bashrc
```

7. Terraform

8. Pyspark