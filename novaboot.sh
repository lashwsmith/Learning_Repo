
#Function to change the region based on user input
region_func ()
{
echo "Please select a region (east/west): "
read region

if [ $region == "west" ]; then	
	OS_REGION_NAME=region-a.geo-1
	OS_AUTH_URL=https://region-a.geo-1.identity.hpcloudsvc.com:35357/v2.0/
		

elif [ $region == "east" ]; then
	OS_REGION_NAME=region-b.geo-1
	OS_AUTH_URL=https://region-b.geo-1.identity.hpcloudsvc.com:35357/v2.0/
	

else

	echo "Please re-enter your region: "
	region_func

fi
}


#THIS FUNCTION WILL CREATE AN EPHEMERAL INSTANCE (NO BOOTABLE VOLUME)
eph_func ()
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

#THIS FUNCTION WILL USE A BOOTABLE VOLUME TO CREATE THE INSTANCE
per_func ()
{
echo "Booting New Server"

echo "Please enter the number of servers you would like to create: "
read number

echo "Please enter a Flavor ID from the list: "
nova flavor-list
read flavor_id

#select the bootable volume to use
echo "Please select the bootable volume ID"
cinder list
read volume_id

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



#Function to create the EPHEMERAL instance based on user input.
eph_confirm ()
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

#Function to create the PERSISTENT instance based on user input.
per_confirm ()
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
                nova boot --flavor $flavor_id --image $image_id --key-name $key_pair --availability-zone $avail_zone --block_device_mapping vda=$volume_id:::0 --nic net-id=$net_id $instance_name-$i
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



#JIT GOES HAM IN THE DOLLAR STORE BELOW THIS
#VVVVVVVVVVVVVVVVVVVVVVVVVVVV
if [ $(which apt-get 2>/dev/null | grep -c "apt-get") -eq 1 ]; then
    INSTALLER_TYPE='sudo apt-get -y install'

		if [ $(dpkg-query -W -f='${Status}' python-novaclient 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
			echo "Nova CLI client is not installed. Would you like to install it now? (y/n)"
				read cli_input
				if [ $cli_input == "y" ]; then
		
						echo "***INSTALLING NOVA CLIENT***"
						$INSTALLER_TYPE python-novaclient		

				else echo "Please install the necessary CLI tools. Terminating."
				exit
				fi

		elif [ $(dpkg-query -W -f='${Status}' python-neutronclient 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
			echo "Neutron CLI client is not installed. Would you like to install it now? (y/n)"
				read cli_input
				if [ $cli_input == "y" ]; then
		
						echo "***INSTALLING NEUTRON CLIENT***"
						$INSTALLER_TYPE python-neutronclient
			
				else echo "Please install the necessary CLI tools. Terminating."
				exit
				fi
			
		elif [ $(dpkg-query -W -f='${Status}' python-glanceclient 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
			echo "Glance CLI client is not installed. Would you like to install it now? (y/n)"
				read cli_input
				if [ $cli_input == "y" ]; then

						echo "***INSTALLING GLANCE CLIENT***"
						$INSTALLER_TYPE python-glanceclient

				else echo "Please install the necessary CLI tools. Terminating."
				exit
				fi

		elif [ $(dpkg-query -W -f='${Status}' python-cinderclient 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
			echo "Cinder CLI client is not installed. Would you like to install it now? (y/n)"
				read cli_input
				if [ $cli_input == "y" ]; then
		
						echo "***INSTALLING CINDER CLIENT***"
						$INSTALLER_TYPE python-cinderclient
		
				else echo "Please install the necessary CLI tools. Terminating."
				exit
				fi
			
		elif [ $(dpkg-query -W -f='${Status}' python-keystoneclient 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
			echo "Keystone CLI client is not installed. Would you like to install it now? (y/n)"
				read cli_input
				if [ $cli_input == "y" ]; then

						echo "***INSTALLING KEYSTONE CLIENT***"
						$INSTALLER_TYPE python-keystoneclient

				else echo "Please install the necessary CLI tools. Terminating."
				exit
				fi
			
		elif [ $(dpkg-query -W -f='${Status}' python-swiftclient 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
			echo "Swift CLI client is not installed. Would you like to install it now? (y/n)"
				read cli_input
				if [ $cli_input == "y" ]; then

						echo "***INSTALLING SWIFT CLIENT***"
						$INSTALLER_TYPE python-swiftclient

				else echo "Please install the necessary CLI tools. Terminating."
				exit
				fi
			
		elif [ $(dpkg-query -W -f='${Status}' python-troveclient 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
			echo "Trove CLI client is not installed. Would you like to install it now? (y/n)"
				read cli_input
				if [ $cli_input == "y" ]; then

						echo "***INSTALLING TROVE CLIENT***"
						$INSTALLER_TYPE python-troveclient

				else echo "Please install the necessary CLI tools. Terminating."
				exit
				fi
			
		else echo "All CLI tools are installed."
		
		fi
		
elif [ $(which yum 2>/dev/null | grep -c "yum") -eq 1 ]; then

	INSTALLER_TYPE="sudo pip install "
	
		if [ $(rpm -qa --queryformat='${Status}' gcc 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
                        
			echo "Installing Pre-reqs"

			sudo yum install libxml2 libxml2-devel libxslt libxslt-devel python-devel libffi-devel openssl-devel gcc

			curl -O https://bootstrap.pypa.io/get-pip.py

			sudo python get-pip.py

			sudo pip install --upgrade setuptools
                                
		fi


		if [ $(which nova; echo $? 2>/dev/null) -ge 1 ]; then
			echo "Nova CLI client is not installed. Would you like to install it now? (y/n)"
				read cli_input
				if [ $cli_input == "y" ]; then
				
	
						echo "***INSTALLING CENTOS NOVA CLIENT***"
						$INSTALLER_TYPE python-novaclient
						
				else echo "Please install the necessary CLI tools. Terminating."
				exit
				fi

		elif [ $(which neutron; echo $? 2>/dev/null) -ge 1 ]; then
			echo "Neutron CLI client is not installed. Would you like to install it now? (y/n)"
				read cli_input

				if [ $cli_input == "y" ]; then
						echo "***INSTALLING NEUTRON CLIENT***"
						$INSTALLER_TYPE python-neutronclient
						
				else echo "Please install the necessary CLI tools. Terminating."
				exit
				fi
			
		elif [  $(which glance; echo $? 2>/dev/null) -ge 1 ]; then
			echo "Glance CLI client is not installed. Would you like to install it now? (y/n)"
				read cli_input		
				if [ $cli_input == "y" ]; then
					
						echo "***INSTALLING GLANCE CLIENT***"
						$INSTALLER_TYPE python-glanceclient
						
				else echo "Please install the necessary CLI tools. Terminating."
				exit
				fi
			
		elif [ $(which cinder; echo $? 2>/dev/null) -ge 1 ]; then
			echo "Cinder CLI client is not installed. Would you like to install it now? (y/n)"
				read cli_input
				if [ $cli_input == "y" ]; then
				
						echo "***INSTALLING CINDER CLIENT***"
						$INSTALLER_TYPE python-cinderclient
						
				else echo "Please install the necessary CLI tools. Terminating."
				exit
				fi
			
		elif [ $(which keystone; echo $? 2>/dev/null) -ge 1 ]; then
			echo "Keystone CLI client is not installed. Would you like to install it now? (y/n)"
				read cli_input
				if [ $cli_input == "y" ]; then
				
						echo "***INSTALLING KEYSTONE CLIENT***"
						$INSTALLER_TYPE python-keystoneclient
						
				else echo "Please install the necessary CLI tools. Terminating."
				exit
				fi
			
		elif [ $(which swift; echo $? 2>/dev/null) -ge 1 ]; then
			echo "Swift CLI client is not installed. Would you like to install it now? (y/n)"
				read cli_input				
				if [ $cli_input == "y" ]; then
					
						echo "***INSTALLING SWIFT CLIENT***"
						$INSTALLER_TYPE python-swiftclient
						
				else echo "Please install the necessary CLI tools. Terminating."
				exit
				fi
			
		elif [ $(which trove; echo $? 2>/dev/null) -ge 1 ]; then
			echo "Trove CLI client is not installed. Would you like to install it now? (y/n)"
				read cli_input				
				if [ $cli_input == "y" ]; then
					
						echo "***INSTALLING TROVE CLIENT***"
						$INSTALLER_TYPE python-troveclient
						
				else echo "Please install the necessary CLI tools. Terminating."
				exit
				fi
			
		else echo "All CLI tools are installed."

		fi
		
	else echo "Clippy: I see you are a nerd. Bring me a suitable distro"
	exit
	
fi

#unset variables just in case!

unset $PROJECT_NAME
unset $HOR_USERNAME
unset $HOR_PASSWORD


#get horizon creds
echo "Please enter your Project NAME"
	read PROJECT_NAME
	OS_TENANT_NAME=$PROJECT_NAME

echo "Please enter your Horizon Username"
	read HOR_USERNAME
	OS_USERNAME=$HOR_USERNAME

echo "Please enter your Horizon Password"
	read -s HOR_PASSWORD
	OS_PASSWORD=$HOR_PASSWORD


#instance type check (ephemeral or persistent)
echo "Will this be an ephemeral or persistent instance?"
read instance_type

    if [ $instance_type == "ephemeral" ]; then
		eph_func

	elif [ $instance_type == "persistent" ]; then
		per_func
	
	fi

region_func


if [ $lamp_check == "n" ]; then

	eph_confirm

elif [ $lamp_check == "y" ]; then

	nova_lamp

else
echo "Please re-enter your information"

fi

rm lampdata.txt
