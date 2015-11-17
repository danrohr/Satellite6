Red Hat Satellite 6 Configuration Script


Script to automate the configuration of Red Hat Satellite 6 after initial installation. It will configure the following:

-Organization

-Label

-Location

-Domain

-Subnet

-Netmask

-Network (with ability to configure multiple networks)

-DNS Server

-RHEL 6 Repositories

-RHEL 7 Repositories

-CentOS 6 Repositories

-CentOS 7 Repositories

-EPEL for CentOS/RHEL 6

-EPEL for CentOS/RHEL 7

-Partitioning (ext4 and xfs)

-DEV, TEST, and PROD lifecycles

-Synchronization plans for all repositories created

-Puppet Forge products and synchronization plans

-Content viess for all products

-Host collections and Activiation keys

-Creations of Operating Systems

-Hostgroups

Important information that is needed to run the script:

In order to run the script the admin user's access to the hammer command Satellite host must be configured.  Along with the manifest file to enable the Red Hat Repositories:

1. Have the manifest file from Red Hat and place it in: /root (this is where the script looks for it) and it should be named something with manifest in its name.
2. mkdir ~/.hammer
3. chmod 600 ~/.hammer
4. create a hammer cli config file in the above directory called:  cli_config.yml
5. The following need to be placed in the file:
6. :foreman:
7.    :host: 'https://satellite hostname here'
8.    :username: 'admin'
9.    :password: 'admin's password here'
10.Save the file and script should be ready
