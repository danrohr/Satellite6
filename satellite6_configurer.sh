#!/bin/bash
###Auto configuration of initial Satellite 6.1 settings
###Created by Dan Rohr 
###v1.0
###8/24/2015
###Initial values and Questions
###comment
cd /root
manifest=$(ls | grep manifest)
if [ -f $manifest ]; then
        echo "Mainfest file is present, continuing"
else
        echo "Please place manifest file in /root and rerun configuration"
        exit 1
fi
echo -n "Enter the built in admin username: "
read admin
echo -n "Enter an organization name: "
read org
echo -n "Enter a label for the organization: "
read label
echo -n "Enter a location name to go with the organization: "
read location
echo -n "Enter a domain: "
read domain
echo -n "Enter a subnet name such as VLAN122: "
read subnet
echo -n "Enter subnet mask such as 255.25.255.0: "
read netmask
echo -n "enter network such address such as 10.1.1.0: "
read network
echo -n "Enter a network name such as 10.1.1.0/24: "
read name
echo -n "Enter more than a single network (Y/N): "
read morenets
echo -n "Enter the IP address of the primary DNS server: "
read dns1
echo -n "Should we enable RHEL 6 repositories ([Y]/N): "
read rhel6
echo -n "Should we enable RHEL 7 repositories ([Y]/N): "
read rhel7
echo -n "Do you want to enable CentOS 6 x86_64 repositories (Y/[N]): "
read centos6
echo -n "Do you want to enable CentOS 7 x86_64 repositories (Y/[N]): "
read centos7
echo "Your Satellite will be configured with the following information:"
echo "Organization: $org"
echo "Label: $label"
echo "Location: $location"
echo "Domain: $domain"
echo "Subnet: $subnet"
echo "Netmask: $netmask"
echo "Network: $network"
echo "Network Name: $name"
echo "More Networks to enter: $morenets"
echo "Primary DNS Server: $dns1"
echo "RHEL 6 Repositories Enabled: $rhel6"
echo "RHEL 7 Repositories Enabled: $rhel7"
echo "CentOS 6 Repositories Enabled: $centos6"
echo "CentOS 7 Repositories Enabled: $centos7"
echo -n "Is this correct ([Y]/N): "
read choice
###
### Create organization, label, and location
if [ "$choice" == N ]; then
        echo -n "Please rerun the script"
        exit 1
else
        hammer organization create --name=$org --label=$label
        hammer organization add-user --user=$admin --name=$org
        hammer location create --name=$location
        hammer location add-user --name=$location --user=$admin
        hammer location add-organization --name=$location --organization=$org
fi
###
###All Partition tables can be replaced with your custom values, the ones Im using are based off of a 50GB disk with left over space to grow the volume
###Populate Partition Table file for RHEL 6
cat <<EOF > /root/RHEL6_Partition
zerombr
clearpart --all --initlabel
part /boot --fstype=ext4 --size=200
part pv.01 --size=1000 --grow
volgroup VolGroup00 pv.01
logvol swap --fstype=swap --vgname=VolGroup00 --name=lv_swap --size=4096
logvol /var --fstype=ext4 --vgname=VolGroup00 --name=lv_var --size=4096
logvol /var/log --fstype=ext4 --vgname=VolGroup00 --name=lv_varlog --size=4096
logvol /var/log/audit --fstype=ext4 --vgname=VolGroup00 --name=lv_varlogaudit --size=4096
logvol / --fstype=ext4 --vgname=VolGroup00 --name=lv_root --size=10240
logvol /home --fstype=ext4 --vgname=VolGroup00 --name=lv_home --size=1024
logvol /tmp --fstype=ext4 --vgname=VolGroup00 --name=lv_tmp --size=2048
logvol /opt --fstype=ext4 --vgname=VolGroup00 --name=lv_opt --size=4096
EOF
###Populate Partition Table file for RHEL 7
cat <<EOF > /root/RHEL7_Partition
zerombr
clearpart --all --initlabel
part /boot --fstype=ext4 --size=200
part pv.01 --size=1000 --grow
volgroup VolGroup00 pv.01
logvol swap --fstype=swap --vgname=VolGroup00 --name=lv_swap --size=4096
logvol /var --fstype=xfs --vgname=VolGroup00 --name=lv_var --size=4096
logvol /var/log --fstype=xfs --vgname=VolGroup00 --name=lv_varlog --size=4096
logvol /var/log/audit --fstype=xfs --vgname=VolGroup00 --name=lv_varlogaudit --size=4096
logvol / --fstype=xfs --vgname=VolGroup00 --name=lv_root --size=10240
logvol /home --fstype=xfs --vgname=VolGroup00 --name=lv_home --size=1024
logvol /tmp --fstype=xfs --vgname=VolGroup00 --name=lv_tmp --size=2048
logvol /opt --fstype=xfs --vgname=VolGroup00 --name=lv_opt --size=4096
EOF
###
###Domains and Subnets
hammer domain create --name=$domain
hammer subnet create --domain-ids=1 --gateway=$gateway --mask=$netmask --name=$subnet --tftp-id=1 --network=$network --dns-primary=$dns1
hammer organization add-subnet --subnet-id=1 --name=$org
hammer organization add-domain --domain-id=1 --name=$org
###
###More networks will be created here
while [ $morenets == "Y" ] 
do	
	echo -n "Enter a subnet name such as VLAN122: "
	read subnet
	echo -n "Enter subnet mask such as 255.25.255.0: "
	read netmask
	echo -n "enter network such address such as 10.1.1.0: "
	read network
	echo -n "Enter a network name such as 10.1.1.0/24: "
	read name
	hammer subnet create --domain-ids=1 --gateway=$gateway --mask=$netmask --name=$subnet --tftp-id=1 --network=$network --dns-primary=$dns1
	hammer organization add-subnet --subnet-id=1 --name=$org
	hammer organization add-domain --domain-id=1 --name=$org
	echo "More networks: (Y/N): "
	read morenets
done
###Subscription Management 
hammer subscription upload --file=$manifest --organization=$org
if [ $rhel6 == Y ]; then
        hammer repository-set enable --organization $org --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='6Server' --name 'Red Hat Enterprise Linux 6 Server (RPMs)'
        hammer repository-set enable --organization $org --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --name 'Red Hat Enterprise Linux 6 Server - Fastrack (RPMs)'
        hammer repository-set enable --organization $org --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='6Server' --name 'Red Hat Enterprise Linux 6 Server - Optional (RPMs)'
        hammer repository-set enable --organization $org --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --name 'Red Hat Enterprise Linux 6 Server - Extras (RPMs)'
        hammer repository-set enable --organization $org --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='6Server' --name 'Red Hat Enterprise Linux 6 Server - RH Common (RPMs)'
        hammer repository-set enable --organization $org --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --name 'Red Hat Enterprise Linux 6 Server - Optional Fastrack (RPMs)'
        hammer repository-set enable --organization $org --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='6Server' --name 'Red Hat Enterprise Linux 6 Server - Supplementary (RPMs)'
        hammer repository-set enable --organization $org --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='6Server' --name 'RHN Tools for Red Hat Enterprise Linux 6 Server (RPMs)'
        hammer repository-set enable --organization $org --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='6Server' --name 'Red Hat Enterprise Linux 6 Server (ISOs)'
        hammer repository-set enable --organization $org --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='6Server' --name 'Red Hat Enterprise Linux 6 Server (Kickstart)'
        hammer repository-set enable --organization $org --product 'Oracle Java for RHEL Server' --basearch='x86_64' --releasever='6Server' --name 'Red Hat Enterprise Linux 6 Server - Oracle Java (RPMs)'
else
        echo "Skipping Red Hat Enterprise Linux 6 Repositories"
fi
if [ $rhel7 == Y ]; then 
	hammer repository-set enable --organization $org --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server (RPMs)'
	hammer repository-set enable --organization $org --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --name 'Red Hat Enterprise Linux 7 Server - Fastrack (RPMs)'
	hammer repository-set enable --organization $org --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server - Optional (RPMs)'  
	hammer repository-set enable --organization $org --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --name 'Red Hat Enterprise Linux 7 Server - Extras (RPMs)'
	hammer repository-set enable --organization $org --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server - RH Common (RPMs)'
	hammer repository-set enable --organization $org --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --name 'Red Hat Enterprise Linux 7 Server - Optional Fastrack (RPMs)'
	hammer repository-set enable --organization $org --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server - Supplementary (RPMs)'
	hammer repository-set enable --organization $org --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'RHN Tools for Red Hat Enterprise Linux 7 Server (RPMs)'
	hammer repository-set enable --organization $org --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server (ISOs)'
	hammer repository-set enable --organization $org --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server (Kickstart)'
	hammer repository-set enable --organization $org --product 'Oracle Java for RHEL Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server - Oracle Java (RPMs)'
else
	echo "Skipping Red Hat Enterprise Linux 7 Repositories"
fi
#EPEL RHEL 6/7
hammer product create --name='EPEL' --organization=$org
hammer repository create --name='EPEL 6 - x86_64' --organization=$org --product='EPEL' --content-type='yum' --publish-via-http=true --url=http://dl.fedoraproject.org/pub/epel/6/x86_64/
hammer repository create --name='EPEL 7 - x86_64' --organization=$org --product='EPEL' --content-type='yum' --publish-via-http=true --url=http://dl.fedoraproject.org/pub/epel/7/x86_64/
if [ $centos6 == Y ]; then
	hammer product create --name='CentOS 6 x86_64' --organization=$org
	hammer repository create --name='CentOS 6 x86_64' --organization=$org --product='CentOS 6 x86_64' --content-type='yum' --publish-via-http=true --url=http://centos.mbni.med.umich.edu/mirror/6/os/x86_64/
else
	echo "Skipping CentOS 6 x86_64 Repositories"
fi
if [ $centos7 == Y ]; then
        hammer product create --name='CentOS 7 x86_64' --organization=$org
        hammer repository create --name='CentOS 7 x86_64' --organization=$org --product='CentOS 7 x86_64' --content-type='yum' --publish-via-http=true --url=http://centos.mbni.med.umich.edu/mirror/7/os/x86_64/
else
        echo "Skipping CentOS 7 x86_64 Repositories"
fi
for i in $(hammer --csv repository list --organization=$org  | awk -F, {'print $1'} | grep -vi '^ID'); do hammer repository synchronize --id ${i} --organization=$org --async; done
###
###Puppet Forge
hammer product create --name='Forge' --organization=$org
hammer repository create --name='Puppet Forge' --organization=$org --product='Forge' --content-type='puppet' --publish-via-http=true --url=https://forge.puppetlabs.com
###
###Create our DEV,TEST,PROD environments
hammer lifecycle-environment create --name='DEV' --prior='Library' --organization=$org
hammer lifecycle-environment create --name='TEST' --prior='DEV' --organization=$org
hammer lifecycle-environment create --name='PROD' --prior='TEST' --organization=$org
###
###Create synchonization plan
hammer sync-plan create --interval=daily --name='Daily sync - Red Hat' --organization=$org --enabled=1
hammer sync-plan create --interval=daily --name='Daily sync - EPEL' --organization=$org --enabled=1
hammer sync-plan create --interval=daily --name='Daily sync - Puppet Forge' --organization=$org --enabled=1
if [ $centos6 == Y ]; then
	hammer sync-plan create --interval=daily --name='Daily sync - CentOS 6' --organization=$org --enabled=1
	hammer product set-sync-plan --sync-plan='Daily sync - CentOS 6' --organization=$org --name='CentOS 6 x86_64'
fi
if [ $centos7 == Y ]; then
	hammer sync-plan create --interval=daily --name='Daily sync - CentOS 7' --organization=$org --enabled=1
	hammer product set-sync-plan --sync-plan='Daily sync - CentOS 7' --organization=$org --name='CentOS 7 x86_64'
fi
hammer product set-sync-plan --sync-plan='Daily sync - Red Hat' --organization=$org --name='Red Hat Enterprise Linux Server'
hammer product set-sync-plan --sync-plan='Daily sync - EPEL' --organization=$org --name='EPEL'
hammer product set-sync-plan --sync-plan='Daily sync - Puppet Forge' --organization=$org --name='Puppet Forge'
###
###Content views
hammer content-view create --name='rhel-6-server-x86_64-cv' --organization=$org
hammer content-view create --name='rhel-7-server-x86_64-cv' --organization=$org
for i in $(hammer --csv repository list --organization=$org | awk -F, {'print $1'} | grep -vi '^ID'); do hammer content-view add-repository --name='rhel-7-server-x86_64-cv' --organization=$org --repository-id=${i}; done
for i in $(hammer --csv repository list --organization=$org | awk -F, {'print $1'} | grep -vi '^ID'); do hammer content-view add-repository --name='rhel-6-server-x86_64-cv' --organization=$org --repository-id=${i}; done
hammer content-view publish --name='rhel-7-server-x86_64-cv' --organization=$org --async
#hammer content-view version promote --organization=$org --to-lifecycle-environment='DEV' --content-view='rhel-7-server-x86_64-cv' --id=3 --async
#hammer content-view version promote --organization=$org --to-lifecycle-environment='TEST' --content-view='rhel-7-server-x86_64-cv' --async
#hammer content-view version promote --organization=$org --to-lifecycle-environment='PROD' --content-view='rhel-7-server-x86_64-cv' --async
hammer content-view publish --name='rhel-6-server-x86_64-cv' --organization=$org --async
#hammer content-view version promote --organization=$org --to-lifecycle-environment='DEV' --content-view='rhel-6-server-x86_64-cv' --id=3 --async
#hammer content-view version promote --organization=$org --to-lifecycle-environment='TEST' --content-view='rhel-6-server-x86_64-cv' --async
hammer content-view version promote --organization=$org --to-lifecycle-environment='PROD' --content-view='rhel-6-server-x86_64-cv' --async
if [ $centos6 == Y ]; then
	hammer content-view create --name='centos-6-server-x86_64-cv' --organization=$org
	hammer content-view publish --name='centos-6-server-x86_64-cv' --organization=$org --async
#	hammer content-view version promote --organization=$org --to-lifecycle-environment='DEV' --content-view='centos-6-server-x86_64-cv' --id=3 --async
#	hammer content-view version promote --organization=$org --to-lifecycle-environment='TEST' --content-view='centos-6-server-x86_64-cv' --async
#	hammer content-view version promote --organization=$org --to-lifecycle-environment='PROD' --content-view='centos-6-server-x86_64-cv' --async
fi
if [ $centos7 == Y ]; then
	hammer content-view create --name='centos-7-server-x86_64-cv' --organization=$org
	hammer content-view publish --name='centos-7-server-x86_64-cv' --organization=$org --async
#	hammer content-view version promote --organization=$org --to-lifecycle-environment='DEV' --content-view='centos-7-server-x86_64-cv' --id=3 --async
#	hammer content-view version promote --organization=$org --to-lifecycle-environment='TEST' --content-view='centos-7-server-x86_64-cv' --async
#	hammer content-view version promote --organization=$org --to-lifecycle-environment='PROD' --content-view='centos-7-server-x86_64-cv' --async
fi
###
###Host collections and Activation Keys
if [ $rhel6 == Y ]; then
	hammer host-collection create --name='RHEL 6 x86_64' --organization=$org
	hammer activation-key create --name='rhel-6-server-x86_64' --organization=$org --content-view='rhel-6-server-x86_64-cv' --lifecycle-environment='Library'
	hammer activation-key add-host-collection --name='rhel-6-server-x86_64' --host-collection='RHEL 6 x86_64' --organization=$org
fi
if [ $rhel7 == Y ]; then
	hammer host-collection create --name='RHEL 7 x86_64' --organization=$org
	hammer host-collection create --name='RHEL 7 x86_64 DEV' --organization=$org
	hammer host-collection create --name='RHEL 7 x86_64 TEST' --organization=$org
	hammer host-collection create --name='RHEL 7 x86_64 PROD' --organization=$org
	hammer activation-key create --name='rhel-7-server-x86_64' --organization=$org --content-view='rhel-7-server-x86_64-cv' --lifecycle-environment='Library'
#	hammer activation-key create --name='rhel-7-server-x86_64_dev' --organization=$org --content-view='rhel-7-server-x86_64-cv' --lifecycle-environment='DEV'
#	hammer activation-key create --name='rhel-7-server-x86_64_test' --organization=$org --content-view='rhel-7-server-x86_64-cv' --lifecycle-environment='TEST'
#	hammer activation-key create --name='rhel-7-server-x86_64_prod' --organization=$org --content-view='rhel-7-server-x86_64-cv' --lifecycle-environment='PROD'
	hammer activation-key add-host-collection --name='rhel-7-server-x86_64' --host-collection='RHEL 7 x86_64' --organization=$org
#	hammer activation-key add-host-collection --name='rhel-7-server-x86_64_dev' --host-collection='RHEL 7 x86_64 DEV' --organization=$org
#	hammer activation-key add-host-collection --name='rhel-7-server-x86_64_test' --host-collection='RHEL 7 x86_64 TEST' --organization=$org
#	hammer activation-key add-host-collection --name='rhel-7-server-x86_64_prod' --host-collection='RHEL 7 x86_64 PROD' --organization=$org
fi
if [ $centos6 == Y ]; then
	hammer host-collection create --name='CentOS 6 x86_64' --organization=$org
	hammer host-collection create --name='CentOS 6 x86_64 DEV' --organization=$org
	hammer host-collection create --name='CentOS 6 x86_64 TEST' --organization=$org
	hammer host-collection create --name='CentOS 6 x86_64 PROD' --organization=$org
	hammer activation-key create --name='centos-6-server-x86_64' --organization=$org --content-view='centos-6-server-x86_64-cv' --lifecycle-environment='Library'
	hammer activationkey add-host-collection --name='centos-6-server-x86_64' --host-collection='CentOS 6 x86_64' --organization=$org
fi
if [ $centos7 == Y ]; then
        hammer host-collection create --name='CentOS 7 x86_64' --organization=$org
        hammer host-collection create --name='CentOS 7 x86_64 DEV' --organization=$org
        hammer host-collection create --name='CentOS 7 x86_64 TEST' --organization=$org
        hammer host-collection create --name='CentOS 7 x86_64 PROD' --organization=$org
        hammer activation-key create --name='centos-7-server-x86_64' --organization=$org --content-view='centos-7-server-x86_64-cv' --lifecycle-environment='Library'
        hammer activationkey add-host-collection --name='centos-7-server-x86_64' --host-collection='CentOS 7 x86_64' --organization=$org
fi
for i in $(hammer --csv activation-key list --organization=$org | awk -F, {'print $1'} | grep -vi '^ID'); do for j in $(hammer --csv subscription list --organization=$org  | awk -F, {'print $8'} | grep -vi '^ID'); do hammer   activation-key add-subscription --id ${i} --subscription-id ${j}; done; done
###
###Partioning, kickstarting, and hostgroups
hammer partition-table create --file RHEL6_Partition --name 'RHEL6_Partition' --os-family 'Redhat'
hammer partition-table create --file RHEL7_Partition --name 'RHEL7_Partition' --os-family 'Redhat'
###Post Configuration
echo "The following items still need to be configured: DEV/TEST/PROD content views"
echo "Scripts are provided to build the host collections, activations, and associations"
echo "Prior to running these scripts edit them and update the --content-view='<name>' section"
echo "Scripts are located /root/ContentViews/"
echo "Puppet files and content if you are synchronizing from a source"
echo "Any authentication providers such as Red Hat Identity Management"
echo "Once all synchronizations are completed the associations and creation of the operating systems will need to be completed"
echo "See /root/OperatingSystemCreation/ directories for scripts to do this"
if [ ! -d /root/ContentViews/ ]; then
	mkdir -p /root/ContentViews/
fi
cat <<EOF > /root/ContentViews/RHEL6
#!/bin/bash
hammer host-collection create --name='RHEL 6 x86_64 DEV' --organization=$org
hammer host-collection create --name='RHEL 6 x86_64 TEST' --organization=$org
hammer host-collection create --name='RHEL 6 x86_64 PROD' --organization=$org
hammer activation-key create --name='rhel-6-server-x86_64_dev' --organization=$org --content-view='<name>' --lifecycle-environment='DEV'
hammer activation-key create --name='rhel-6-server-x86_64_test' --organization=$org --content-view='<name>' --lifecycle-environment='TEST'
hammer activation-key create --name='rhel-6-server-x86_64_prod' --organization=$org --content-view='<name>' --lifecycle-environment='PROD'
hammer activation-key add-host-collection --name='rhel-6-server-x86_64_dev' --host-collection='RHEL 6 x86_64 DEV' --organization=$org
hammer activation-key add-host-collection --name='rhel-6-server-x86_64_test' --host-collection='RHEL 6 x86_64 TEST' --organization=$org
hammer activation-key add-host-collection --name='rhel-6-server-x86_64_prod' --host-collection='RHEL 6 x86_64 PROD' --organization=$org
EOF
cat <<EOF > /root/ContentViews/RHEL7
#!/bin/bash
hammer host-collection create --name='RHEL 7 x86_64 DEV' --organization=$org
hammer host-collection create --name='RHEL 7 x86_64 TEST' --organization=$org
hammer host-collection create --name='RHEL 7 x86_64 PROD' --organization=$org
hammer activation-key create --name='rhel-7-server-x86_64_dev' --organization=$org --content-view='<name>' --lifecycle-environment='DEV'
hammer activation-key create --name='rhel-7-server-x86_64_test' --organization=$org --content-view='<name>' --lifecycle-environment='TEST'
hammer activation-key create --name='rhel-7-server-x86_64_prod' --organization=$org --content-view='<name>' --lifecycle-environment='PROD'
hammer activation-key add-host-collection --name='rhel-7-server-x86_64_dev' --host-collection='RHEL 7 x86_64 DEV' --organization=$org
hammer activation-key add-host-collection --name='rhel-7-server-x86_64_test' --host-collection='RHEL 7 x86_64 TEST' --organization=$org
hammer activation-key add-host-collection --name='rhel-7-server-x86_64_prod' --host-collection='RHEL 7 x86_64 PROD' --organization=$org
EOF
cat <<EOF > /root/ContentViews/CentOS6
#!/bin/bash
hammer host-collection create --name='CentOS 6 x86_64 DEV' --organization=$org
hammer host-collection create --name='CentOS 6 x86_64 TEST' --organization=$org
hammer host-collection create --name='CentOS 6 x86_64 PROD' --organization=$org
hammer activation-key create --name='centos-6-server-x86_64_dev' --organization=$org --content-view='<name>' --lifecycle-environment='DEV'
hammer activation-key create --name='centos-6-server-x86_64_test' --organization=$org --content-view='<name>' --lifecycle-environment='TEST'
hammer activation-key create --name='centos-6-server-x86_64_prod' --organization=$org --content-view='<name>' --lifecycle-environment='PROD'
hammer activation-key add-host-collection --name='centos-6-x86_64_dev' --host-collection='CentOS 6 x86_64 DEV' --organization=$org
hammer activation-key add-host-collection --name='centos-6-server-x86_64_test' --host-collection='CentOS 6 x86_64 TEST' --organization=$org
hammer activation-key add-host-collection --name='centos-6-server-x86_64_prod' --host-collection='CentOS 6 x86_64 PROD' --organization=$org
EOF
cat <<EOF > /root/ContentViews/CentOS7
#!/bin/bash
hammer host-collection create --name='CentOS 7 x86_64 DEV' --organization=$org
hammer host-collection create --name='CentOS 7 x86_64 TEST' --organization=$org
hammer host-collection create --name='CentOS 7 x86_64 PROD' --organization=$org
hammer activation-key create --name='centos-7-server-x86_64_dev' --organization=$org --content-view='<name>' --lifecycle-environment='DEV'
hammer activation-key create --name='centos-7-server-x86_64_test' --organization=$org --content-view='<name>' --lifecycle-environment='TEST'
hammer activation-key create --name='centos-7-server-x86_64_prod' --organization=$org --content-view='<name>' --lifecycle-environment='PROD'
hammer activation-key add-host-collection --name='centos-7-server-x86_64_dev' --host-collection='CentOS 7 x86_64 DEV' --organization=$org
hammer activation-key add-host-collection --name='centos-7-server-x86_64_test' --host-collection='CentOS 7 x86_64 TEST' --organization=$org
hammer activation-key add-host-collection --name='centos-7-server-x86_64_prod' --host-collection='CentOS 7 x86_64 PROD' --organization=$org
EOF
###
###Operating System Creations
if [ ! -d /root/OperatingSystemCreation ]; then
	mkdir -p /root/OperatingSystemCreation
fi
#RHEL 6
cat <<EOF > /root/OperatingSystemCreation/RHEL6
#!/bin/bash
PARTID=$(hammer --csv partition-table list | grep 'RHEL6_Partition' | awk -F, {'print $1'})
for i in $(hammer --csv os list | awk -F, {'print $1'} | grep -vi '^ID')
  do
    hammer partition-table add-operatingsystem --id="${PARTID}" --operatingsystem-id="${i}"
  done
#Kickstart PXE template to OS
PXEID=$(hammer --csv template list | grep 'Kickstart default PXELinux' | awk -F, {'print $1'})
SATID=$(hammer --csv template list | grep 'Satellite Kickstart Default' | awk -F, {'print $1'})
for i in $(hammer --csv os list | awk -F, {'print $1'} | grep -vi '^ID')
  do
    hammer template add-operatingsystem --id="${PXEID}" --operatingsystem-id="${i}"
    hammer os set-default-template --id="${i}" --config-template-id="${PXEID}"
    hammer os add-config-template --id="${i}" --config-template-id="${SATID}"
    hammer os set-default-template --id="${i}" --config-template-id="${SATID}"
   done
#RHEL 6 Hostgroup
MEDID=$(hammer --csv medium list | grep 'Red_Hat_Enterprise_Linux_6_Server_Kickstart_x86_64_6_7' | awk -F, {'print $1'})
ENVID=$(hammer --csv environment list | awk -F, {'print $1'})
PARTID=$(hammer --csv partition-table list | grep 'RHEL6_Partition' | awk -F, {'print $1'})
OSID=$(hammer --csv os list | grep 'RedHat 6.7' | awk -F, {'print $1'})
CAID=1
PROXYID=1
hammer hostgroup create --architecture="x86_64" --domain=$domian --environment-id="${ENVID}" --medium-id="${MEDID}" --name="RHEL 6 x86_64" --subnet=$subnet --partition-table-id="${PARTID}" --operatingsystem-id="${OSID}" --puppet-ca-proxy-id="${CAID}" --puppet-proxy-id="${PROXYID}"
EOF
cat <<EOF > /root/OperatingSystemCreation/RHEL7
#!/bin/bash
#RHEL 7
PARTID=$(hammer --csv partition-table list | grep 'RHEL7_Partition' | awk -F, {'print $1'})
for i in $(hammer --csv os list | awk -F, {'print $1'} | grep -vi '^ID')
  do
    hammer partition-table add-operatingsystem --id="${PARTID}" --operatingsystem-id="${i}"
  done
#RHEL 7 Hostgroup
MEDID=$(hammer --csv medium list | grep 'Red_Hat_Enterprise_Linux_7_Server_Kickstart_x86_64_7_1' | awk -F, {'print $1'})
ENVID=$(hammer --csv environment list | awk -F, {'print $1'})
PARTID=$(hammer --csv partition-table list | grep 'RHEL6_Partition' | awk -F, {'print $1'})
OSID=$(hammer --csv os list | grep 'RedHat 7.1' | awk -F, {'print $1'})
CAID=1
PROXYID=1
hammer hostgroup create --architecture="x86_64" --domain=$domian --environment-id="${ENVID}" --medium-id="${MEDID}" --name="RHEL 7 x86_64" --subnet=$subnet --partition-table-id="${PARTID}" --operatingsystem-id="${OSID}" --puppet-ca-proxy-id="${CAID}" --puppet-proxy-id="${PROXYID}"
EOF
