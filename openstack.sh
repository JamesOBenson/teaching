#  Be sure to have the following pre-req packages:
# sudo apt-get install -y python-pip
# sudo pip install python-openstackclient

# Set your servername
export servername="Benson-wp"
export keypairname=wordpress-keypair

#show VM's that are created
openstack server list --insecure

# Show available images to boot from and select Ubuntu 16.04 LTS
openstack image list --insecure
imageID=`openstack image list --insecure | grep 'Ubuntu 16.04 LTS' | awk '{print $2}'`
# output: 40102838-75a5-4249-af47-94f2d925d165

# Show available flavors (VM sizes) and select the m1.small
openstack flavor list --insecure
flavorID=`openstack flavor list --insecure | grep 'm1.small' | awk '{print $2}'`
# output: 2

# Create a public and private Keypair to be able to log into the VM
openstack  keypair create $keypairname --insecure > $keypairname
chmod 600 $keypairname

# Create the VM
openstack server create --image $imageID --flavor=$flavorID --key-name=$keypairname $servername --insecure
# openstack server create --image=40102838-75a5-4249-af47-94f2d925d165 --flavor=2 --key-name=wordpress-keypair wordpress --insecure

# Create a floating IP:
openstack network list --insecure
networkname=`openstack network list --insecure | grep 'admin_floating_net' | awk '{print $4}'`
floatingIP=`openstack floating ip create $networkname --insecure  | grep 'floating_ip_address' | awk '{print $4}'`

openstack server add floating ip $servername $floatingIP --insecure

sleep 5
openstack server list --insecure
echo "ssh into your VM by:  ssh -i $keypairname ubuntu@$floatingIP"
