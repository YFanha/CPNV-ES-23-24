#!/bin/bash

# --------------- Functions ----------------
function installTools(){
	apt-get install mdadm curl unzip parted -y

	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
	unzip awscliv2.zip
	./aws/install
}

function setupAWS(){
	export AWS_ACCESS_KEY_ID=<awsKeyID>
	export AWS_SECRET_ACCESS_KEY=<awsSecKey>
	export AWS_DEFAULT_REGION=eu-south-1
	export AWS_DEFAULT_OUTPUT=json
}

function delAWSkeys(){
	unset AWS_ACCESS_KEY_ID
	unset AWS_SECRET_ACCESS_KEY
	unset AWS_DEFAULT_REGION
	unset AWS_DEFAULT_OUTPUT
}

function downloadData(){
	from s3...
}

function extendRAID(){

	downloadData
}

if [ "$#" -lt 1 ]
then
  echo -e 'No arguments supplied.\n$0 -h to display the help'
  exit 1
fi

while getopts 'i:' OPTION; do
    case "$OPTION" in
        i)
            installTools
        *)
            # Print helping message
            
            # Terminate from the script
            exit 1 ;;
    esac
done

# Remove all options passed by getopts options
shift "$(($OPTIND -1))
extendRAID