#!/bin/bash

region_func ()
{
echo "Please select a region (east/west): "
read region

if [ $region == "west" ]; then
 	sed 's/OS_REGION_NAME=region-b.geo-1/OS_REGION_NAME=region-a.geo-1/g' /etc/.bashrc
	

elif [ $region == "east" ]; then
	sed 's/OS_REGION_NAME=region-a.geo-1/OS_REGION_NAME=region-b.geo-1/g' /etc/.bashrc

else

	echo "Please re-enter your region: "
	region_func

fi
}

read_func ()
{
echo "Booting New Server"

echo "Number of servers:"
read number

echo "Please enter a Flavor ID from the list: "
nova flavor-list
read flavor_id

echo "Please enter an Image ID: "
glance image-list
read image_id

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

echo "Booting instance with the following information: "
echo "Flavor: $flavor_id"
echo "Image ID: $image_id"
echo "Key Pair Name: $key_pair"
echo "Availability Zone: $avail_zone"
echo "Network ID: $net_id"
echo "Instance Name: $instance_name"

echo "Is the above information correct?"
read user_input
}

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

region_func

read_func

nova_confirm
