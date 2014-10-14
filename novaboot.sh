#!/bin/bash

function read_func ()
{
echo "Booting New Server"

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

function nova_confirm ()
{
if [ $user_input != "y" ]; then
        echo "Please re-enter your information"
        read_func
fi
if [ $user_input == "y" ]; then
	echo "******Booting New Instance******"
        nova boot --flavor $flavor_id --image $image_id --key-name $key_pair --availability-zone $avail_zone --nic net-id=$net_id $instance_name
fi
}

read_func

nova_confirm
