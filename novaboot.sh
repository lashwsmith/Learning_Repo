#!/bin/bash


#Function to change the region based on user input
region_func ()
{
echo "Please select a region (east/west): "
read region

if [ $region == "west" ]; then
 	sed -i 's/OS_REGION_NAME=region-b.geo-1/OS_REGION_NAME=region-a.geo-1/g' ~/.bashrc
	sed -i 's/OS_AUTH_URL=https:\/\/region-b.geo-1.identity.hpcloudsvc.com:35357\/v2.0\//OS_AUTH_URL=https:\/\/region-a.geo-1.identity.hpcloudsvc.com:35357\/v2.0\//g' ~/.bashrc
	source ~/.bashrc

elif [ $region == "east" ]; then
	sed -i 's/OS_REGION_NAME=region-a.geo-1/OS_REGION_NAME=region-b.geo-1/g' ~/.bashrc
	sed -i 's/OS_AUTH_URL=https:\/\/region-a.geo-1.identity.hpcloudsvc.com:35357\/v2.0\//OS_AUTH_URL=https:\/\/region-b.geo-1.identity.hpcloudsvc.com:35357\/v2.0\//g' ~/.bashrc
	source ~/.bashrc

else

	echo "Please re-enter your region: "
	region_func

fi
}


#Function to store user input in variables for use in the nova command
read_func ()
{
echo "Booting New Server"

echo "Please enter the number of servers you would like to create: "
read number

echo "Please enter a Flavor ID from the list: "
nova flavor-list
read flavor_id

#call to function to select the glance image to use
os_select

echo "Please enter a Keypair name: "
nova keypair-list
read key_pair

echo "Please enter an Availability Zone: "
nova availability-zone-list
read avail_zone

echo "Please enter a Network ID: "
neutron net-list
read net_id

echo "Please enter a name for the instance: "
read instance_name

echo "Would you like to make this instance a LAMP server? (y/n): "
read lamp_check

echo "Booting instance with the following information: "
echo "Flavor: $flavor_id"
echo "Image ID: $image_id"
echo "Key Pair Name: $key_pair"
echo "Availability Zone: $avail_zone"
echo "Network ID: $net_id"
echo "Instance Name: $instance_name"
echo "LAMP stack: $lamp_check"

echo "Is the above information correct? (y/n): "
read user_input
}


#Function to create the server based on user input.
nova_confirm ()
{
while [ $user_input == "n" ]
do
	echo "Please re-enter your information"
	read_func
	done

if [ $user_input == "y" ]; then
	i=1
	while [[ $i -le $number ]]
	do
		echo "******Booting New Instance******"
		nova boot --flavor $flavor_id --image $image_id --key-name $key_pair --availability-zone $avail_zone --nic net-id=$net_id $instance_name-$i
	((i = i + 1))
	done
fi
}


#Function to create the server with LAMP stack installed through user-data
nova_lamp ()
{
while [ $user_input == "n" ]
do
        echo "Please re-enter your information"
        read_func
        done

if [ $user_input == "y" ]; then
        i=1
        while [[ $i -le $number ]]
        do
                echo "******Booting New Instance******"
                nova boot --flavor $flavor_id --user-data lampdata.txt --image $image_id --key-name $key_pair --availability-zone $avail_zone --nic net-id=$net_id $instance_name-$i
        ((i = i + 1))
        done
fi
}



#Function to choose which OS to use.
os_select ()
{
echo -e "Please enter an Image type\na.) ubuntu\nb.) centos\nc.) debian\nd.) suse\ne.) windows"
read os_choice

        if [ $os_choice = 'a' ]; then
                glance image-list | grep 'Ubuntu'
                read image_id

        elif [ $os_choice = 'b' ]; then
                glance image-list | grep 'CentOS'
                read image_id

        elif [ $os_choice = 'c' ]; then
                glance image-list | grep 'Debian'
                read image_id

        elif [ $os_choice = 'd' ]; then
                glance image-list | grep 'SUSE'
                read image_id

        elif [ $os_choice = 'e' ]; then
                glance image-list | grep 'Windows'
                read image_id

        else
                echo "Please select an Image type"
                os_select

        fi
}



#Initial check to verify that the CLI Tools are installed. If they are installed, script will continue boot process; if not, script will ask/install tools.
if [ $(dpkg-query -W -f='${Status}' python-novaclient 2>/dev/null | grep -c "ok installed") -eq 0 ] || [ $(dpkg-query -W -f='${Status}' python-neutronclient 2>/dev/null | grep -c "ok installed") -eq 0 ] || [ $(dpkg-query -W -f='${Status}' python-glanceclient 2>/dev/null | grep -c "ok installed") -eq 0 ] || [ $(dpkg-query -W -f='${Status}' python-cinderclient 2>/dev/null | grep -c "ok installed") -eq 0 ] || [ $(dpkg-query -W -f='${Status}' python-keystoneclient 2>/dev/null | grep -c "ok installed") -eq 0 ] || [ $(dpkg-query -W -f='${Status}' python-swiftclient 2>/dev/null | grep -c "ok installed") -eq 0 ] || [ $(dpkg-query -W -f='${Status}' python-troveclient 2>/dev/null | grep -c "ok installed") -eq 0 ]; then

                echo "One or more of the CLI Tools are not installed. Would you like to install them now? (y/n)"
                read cli_input

                if [ $cli_input == "y" ]; then

                        echo "**INSTALLING CLI TOOLS NOW**"
                        sudo apt-get -y install python-novaclient python-neutronclient python-glanceclient python-cinderclient python-keystoneclient python-swiftclient python-troveclient

                else
                        echo "Please install the CLI Tools before continuing"
                        exit

                fi

fi



region_func
read_func


if [ $lamp_check == "n" ]; then

	nova_confirm

elif [ $lamp_check == "y" ]; then

	nova_lamp

else
echo "Please re-enter your information"

fi
