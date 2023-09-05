#!/bin/bash
if [ "$#" -lt 1 ]
then
  echo -e 'No arguments supplied.\n$0 -h to display the help'
  exit 1
fi

while getopts 'i:d:r:f:m:h:' OPTION; do
    case "$OPTION" in
        i)
            if [[ $OPTARG == 'true' ]]; then
               apt-get install mdadm -y
            fi ;;
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
shift "$(($OPTIND -1))"

function createRaid(){
	echo "${#disks[@]}"
	
	nbrDisks=${#disks[@]}

	for array in "${disks[@]}"; do
	    echo $array
	done	

	# Create the raid with the disks
	mdadm --create $raidDevice --level=$raidLevel --raid-devices=$nbrDisks ${disks[@]}
	
	# Format the raid partition
	mkfs -t $raidFormat $raidDevice
	
	raidUUID=$(blkid -o value -s UUID $raidDevice)
	
	# Mount the raid
	mount $raidDevice $raidMountPoint
	
	# Entry in /etc/fstab for persitency
	echo "UUID=$raidUUID $raidMountPoint  ext4 defaults 0 0" >> /etc/fstab
}

if [[ ( "$#" -lt 2 && ( "$raidLevel" == '1' || "$raidLevel" == '0' )) || ( "$raidLevel" == '5' && "$#" -lt 3 ) ]]; then
  echo "Not enough disks specified"
else
  disks=( "$@" )
	createRaid
fi