# define raid options
raidDevice='/dev/md0'
raidLevel='0' # 0,1
raidMountPoint='/mnt'

# install tool mdadm
apt-get install mdadm -y

# Get initial config
lsblk >> ~/lsblk.base

# Create the raid with the 2 devices
mdadm --create $raidDevice --level=$raidLevel --raid-devices=2 /dev/sdb /dev/sdc

# Format the raid part. in ext4
mkfs -t ext4 $raidDevice

raidUUID=$(blkid -o value -s UUID $raidDevice)

# Mount the raid
mount $raidDevice $raidMountPoint

# Entry in /etc/fstab for persitency
echo "UUID=$raidUUID $raidMountPoint  ext4 defaults 0 0" >> /etc/fstab

# Get details of the RAID
mdadm --detail --scan $raidDevice >> /etc/mdadm/mdadm.conf

# Get final config
lsblk >> ~/lsblk.raid