#!/bin/bash
# Define constants
curHost=$(hostname)
ipAddr=$(hostname -I)
# Colors
NC='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
# Define Functions
buildMySQL () {
	read -p 'Input desired MySQL database name: ' mysqldb
	read -p 'Input desired MySQL username: ' mysqlusr
	read -p 'Input desired MySQL user password: ' mysqlpwd
	echo -e Creating MySQL database ${YELLOW}$mysqldb ${NC}for ${YELLOW}$mysqlusr ${NC} with your chosen password
	echo -e You will be prompted for ${RED}root ${NC}MySQL password
	mysql -u root -p -e "CREATE DATABASE ${mysqldb};GRANT ALL PRIVILEGES ON ${mysqldb}.* TO ${mysqlusr}@'localhost' IDENTIFIED BY '${mysqlpwd}';FLUSH PRIVILEGES;"
	echo -e Database created ${GREEN}successfully!${NC}
	echo -e Permissions assigned and flushed ${GREEN}successfully!${NC}
}
checkFileSize () {
	read -p 'Input IP/Hostname of remote host: ' remoteHost
	read -p 'Input username with permissions on remote host: ' remoteUser
	read -p 'Input /path/to/directory that will be synced to local machine: ' remotePath
	echo "Checking total file size (this may take some time)..."
	dirSize=$(ssh ${remoteUser}@${remoteHost} du -hs $remotePath)
	echo -e Total directory size is${RED} ${dirSize:0:4} ${NC}and will be synced to this machine.
	echo Proceed with rsync?
	select yn in "Yes" "No"; do
		case $yn in
			Yes ) doRsync; break;;
			No ) break;;
		esac
	done

}
createBackups () {
	echo Creating backups...
	echo Copy /etc/hostname ... /etc/hostname.bak
	cp /etc/hostname /etc/hostname.bak
	echo -e ${GREEN}Created successfully!${NC}
	echo Copy /etc/hosts ... /etc/hosts.bak
	cp /etc/hosts /etc/hosts.bak
	echo -e ${GREEN}Created successfully!${NC}
	echo Copy /etc/network/interfaces ... /etc/network/interfaces.bak
	cp /etc/network/interfaces /etc/network/interfaces.bak
	echo -e ${GREEN}Created successfully!${NC}
	echo Backups completed, begin configuration
	}
setHostname () {
	read -p 'Input desired hostname: CAIU-Moodle-' newHost
	echo Setting system hostname to CAIU-Moodle-$newHost
	sed -i "s/STRIPPED/$newHost/" /etc/hostname
	echo Changing /etc/hosts to accommodate $newHost
	sed -i "s/STRIPPED/$newHost/" /etc/hosts
	echo -e ${GREEN}Success!${NC}
}
setIP () {
	read -p 'Input desired IP Address: ' newIP
	echo Setting system IP to ${GREEN}$newIP ${NC}
	sed -i "s/10.248.28.199/$newIP/" /etc/network/interfaces
	echo Changing /etc/hosts to accommodate $newIP
	sed -i "s/10.248.28.199/$newIP/" /etc/hosts
	echo -e ${GREEN}Success!${NC}
}
echo =================================================================
echo Welcome to Moodle migration!
echo
echo This script will help you break out Moodle into its own instance.
echo =================================================================
# Check to make sure script is being run as root user, else quit.
echo Checking for root...
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   echo -e ${RED}Critical failure!${NC}Script will now terminate.
   exit 1
fi
# Return success
echo Success! Begin housework
echo .....................
# Backup any files that will be touched with this script
echo "Perform backups before proceeding?"
select yn in "Yes" "No"; do
	case $yn in
		Yes ) createBackups; break;;
		No ) break;;
	esac
done
echo .....................
# User defines variables beyond this point
echo -e Current IP Address is ${YELLOW}$ipAddr ${NC}and will need to be changed.
# Backup any files that will be touched with this script
echo "New IP will be set. Proceed?"
select yn in "Yes" "No"; do
	case $yn in
		Yes ) setIP; break;;
		No ) break;;
	esac
done
echo -e Current Hostname is ${YELLOW}$curHost ${NC}and will need to be changed.
echo "New hostname will be set. Proceed?"
select yn in "Yes" "No"; do
	case $yn in
		Yes ) setHostname; break;;
		No ) break;;
	esac
done
echo .....................
echo Migration will now provision necessary MySQL database and permissions
echo "This action will create a user and build a new database. Proceed?"
select yn in "Yes" "No"; do
	case $yn in
		Yes ) buildMySQL; break;;
		No ) break;;
	esac
done
echo .....................
echo Migration will now prepare to sync files from remote host to this machine
echo -e ${YELLOW}Warning! Warning! Warning! Warning!${NC}
echo Please ensure that any mounts are active prior to procceding. If you are missing any
echo mount points, please re-run this script after creating them in /etc/fstab
echo "Proceed with data migration (this may take some time)?"
select yn in "Yes" "No"; do
	case $yn in
		Yes ) checkFileSize; break;;
		No ) break;;
	esac
done
