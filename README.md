# Trade Flows Analysis Pipeline
## Introduction
This repository contains a data pipeline for ingesting and analysing trade data contained in the BACI database, which is maintained by [CEPII](https://www.cepii.fr/CEPII/en/bdd_modele/bdd_modele_item.asp?id=37). This repository has been created for the purpose of being submitted as project for the [Data Engineering Zoomcamp](https://github.com/DataTalksClub/data-engineering-zoomcamp)

## Project goal
The goal of this project is to analyze trade flows between countries, specifically the trade of goods. The BACI database contains data on bilateral trade flows for 200 countries at the product level, classified according to the "Harmonized System" (HS) nomenclature.
This project focuses on analysing two aspects of trade:
1. The total value of goods exported and imported by a country in a given year, as well as the corresponding trade deficit (calculated as the value of exports minus value of imports)
2. The total value of goods exported and imported per country for a given HS code, in order to identify the most important exporters and importers of a given category of goods.
Note that services are not included in the trade data, therefore their value is not considered at any point in this project. Therefore the trade deficit reflects only the trade deficit of goods.

## Infrastructure and Pipeline
The project was developed fully in the cloud, by using a Google Cloud Virtual Machine (VM). 

## Requirements
- An account on Google Cloud Platform (GCP) with credits

## Setup
In case you would like to run the data pipeline, follow the steps described below.
1. On GCP, create a new project
2. Create a service account and assign the "Storage Admin", "BigQuery Admin", "Compute Admin", and "Dataproc Administrator" roles to it
To keep things simple, only one service account is created for the purpose of this project.
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

Clone the repository
```
git clone https://github.com/DavidVFitzGerald/trade-flows-analysis.git
```

7. Terraform
Create bin directory in top-level directory.
```
mkdir bin
```

In the bin directory, download the Terraform binary for Linux
```
wget https://releases.hashicorp.com/terraform/1.11.4/terraform_1.11.4_linux_amd64.zip
```

Install unzip to unzip the terraform binary file.
```
sudo apt install unzip
```
```
unzip terraform_1.11.4_linux_amd64.zip
```
```
rm terraform_1.11.4_linux_amd64.zip
```

Add bin folder to the PATH variable so that terraform is visible from any directory. Edit the .bashrc file to add the following line at the end:
```
export PATH="${HOME}/bin:${PATH}"
```

Google Cloud Authentication

Create a directory named ".gc" and save in there the service account credentials json file

In case you are not running the code on a VM created on GCP, you will need to install the Google Cloud SDK (for the purpose of using the gcloud CLI).

Once gcloud CLI is available, run the following command

Configure google cloud CLI
```
export GOOGLE_APPLICATION_CREDENTIALS=~/.gc/[KEY_FILENAME].json
```
```
gcloud auth activate-service-account --key-file $GOOGLE_APPLICATION_CREDENTIALS
```


Run terraform:
In the terraform/variables.tf file, edit the variables "credentials", "project", "region" and "location" to adapt them to your Google Cloud setup.

To make it possible to launch a cluster with terraform, the service account used for authenticating to google cloud will need to be granted permission to act upon the service account of compute engine. Go to the service accounts page in google cloud platform, click on the account of the compute engine, go to the Permissions tab, select the compute engine service account and click on the Grant access button. Under Add principals, type the name of the service account created for the project (i.e. the one used for authenticating the VM to google cloud). As role, add "Service Account User". Click save.

Run the following commands to set the infrastructure up:
```
terraform init
```
```
terraform plan
```
```
terraform apply
```

8. Pyspark
Enable Dataproc API



Notes and possible improvements:
There are many more ways in which the data could be analysed and presented. The analysis done in Looker Studio was kept to a minimum due to time constraints.
While the BACI database contains data for different version of the HS classification system, and the pipeline was setup in such a way that the version can be provided as argument, it is recommended to use the HS17 for analysing the latest trends in trade, as it is the version for which most countries reported data in recent years. Eventually, HS22 will be used more widely in the future. But as it does not have date for many previous years, HS17 was used as default version for this project. Older version of HS should be used when analysing old trade flows. For a more detailed description of the differences between the different HS versions, please consult the documentation provided by CEPII: https://www.cepii.fr/DATA_DOWNLOAD/baci/doc/DescriptionBACI.html.
There is likely quite a lot of room for optimizing the infrastructure. The size of the data that is handled is quite small, meaning that the infrastructure used (inlcuding the spark cluster) is probably an overkill.

