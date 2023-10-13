#!/bin/bash

# --------------- Functions ----------------
function installTools(){
	apt-get install mdadm curl unzip parted -y

	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
	unzip awscliv2.zip
	./aws/install
}

function downloadData(){
	wget https://go.microsoft.com/fwlink/p/?linkid=2195333
	wget https://go.microsoft.com/fwlink/p/?LinkID=2195280&clcid=0x409&culture=en-us&country=US
}

function createRaid(){
	nbrDisks=${#disks[@]}

  # Create the raid with the disks
  echo "Creating the RAID..."
  mdadm --create "$raidDevice" --level="$raidLevel" --raid-devices="${#disks[@]}" "${disks[@]}"

  # Format the raid partition
  mkfs -t $raidFormat $raidDevice

  raidUUID=$(blkid -o value -s UUID $raidDevice)

  echo "Mounting the RAID..."
  # Mount the raid
  mkdir -p $raidMountPoint
  mount $raidDevice $raidMountPoint

  echo "Writing in fstab for persistency..."
  # Entry in /etc/fstab for persitency
  echo "UUID=$raidUUID $raidMountPoint  ext4 defaults 0 0" | tee -a /etc/fstab

	downloadData
}

if [ "$#" -lt 1 ]
then
  echo -e 'No arguments supplied.\n$0 -h to display the help'
  exit 1
fi

while getopts 'i:d:r:m:f:' OPTION; do
    case "$OPTION" in
        i)
            installTools ;;
        d)
            raidDevice=$OPTARG ;;
        r)
            raidLevel=$OPTARG ;;
        m)
            raidMountPoint=$OPTARG ;;
				f)
						raidFormat=$OPTARG ;;
        *)
            # Print helping message
            echo -e '\n'
            echo "Usage: $0 [-i value] [-d value] [-r value] [-f value] [-m value] <disks> <disks> ..."
						echo "-i Set to 'true' if it is needed to install the mdadm tool."
            echo "-d Device name. e.g. /dev/mdX."
            echo "-r Raid type to configure."
						echo "-f Format of the partition."
            echo "-m Mount point."
            echo -e '\n\n'
            # Terminate from the script
            exit 1 ;;
    esac
done

# Remove all options passed by getopts options
shift "$(($OPTIND -1))

if [[ ( "$#" -lt 2 ) || ( "$raidLevel" == '5' && "$#" -lt 3 ) ]]; then
  echo "Not enough disks specified"
else
  disks=( "$@" )
	createRaid
fi