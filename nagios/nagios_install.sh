#!/bin/bash

yum -y install nagios              #Install, start and enable nagios
systemctl enable nagios
systemctl start nagios

setenforce 0                       # Turn off SElinux, so it doesn't trip us up

systemctl enable httpd             # Enable and start apache
systemctl start httpd

yum -y install nrpe                # Install, enable, and start nrpe, the nagios client
systemctl enable nrpe
systemctl start nrpe
yum -y install nagios-plugins-all
yum -y install nagios-plugins-nrpe

htpasswd -b /etc/nagios/passwd nagiosadmin nagiosadmin      # set the nagios admin password
sed -i 's,allowed_hosts=127.0.0.1,allowed_hosts=127.0.0.1\,10.128.0.0\/20,g' /etc/nagios/nrpe.cfg
# the above enables connections from your subnet, please ajust to be your subnet!

sed -i 's,dont_blame_nrpe=0,dont_blame_nrpe=1,g' /etc/nagios/nrpe.cfg
# enable NRPE monitoring

mkdir /etc/nagios/servers
# create a directory for our server configuration and enable it in the config file
sed -i 's,#cfg_dir=/etc/nagios/servers,cfg_dir=/etc/nagios/servers,g' /etc/nagios/nagios.cfg
systemctl restart nagios

cd /etc/nagios/servers

# Now take a break, and spin up a machine called example-a with all the nrpe plugins installed and a propperly configured path
# to nagios
# put it's ip address into the address column below

echo '# Define a host for an example-a machine
define host{
        use                     linux-server
        host_name               example-a
        alias                   example-a
        address                 10.138.0.2
        }
###############################################################################
###############################################################################
#
# SERVICE DEFINITIONS
#
###############################################################################
###############################################################################
# Define a service to ping the example-a machine
define service{
        use                             generic-service         ; Name of service template to use
        host_name                       example-a
        service_description             PING
        check_command                   check_ping!100.0,20%!500.0,60%
        }
# Define a service to check HTTP on the example-a machine.
# Disable notifications for this service by default, as not all users may have HTTP enabled.
define service{
        use                             generic-service         ; Name of service template to use
        host_name                       example-a
        service_description             HTTP
        check_command                   check_http
        notifications_enabled           0
        }
# Define a service to check the disk space of the root partition
# on the example-a machine.  Warning if < 20% free, critical if
# < 10% free space on partition.
define service{
        use                             generic-service         ; Name of service template to use
        host_name                       example-a
        service_description             Root Partition
        check_command			              check_nrpe!check_disk!20%!10%!/
        }
# Define a service to check the number of currently logged in
# users on the example-a machine.  Warning if > 20 users, critical
# if > 50 users.
define service{
        use                             generic-service         ; Name of service template to use
        host_name                       example-a
        service_description             Current Users
        check_command			              check_nrpe!check_users!20!50
        }
# Define a service to check the number of currently running processes
# on the example-a machine.  Warning if > 250 processes, critical if
# > 400 processes.
define service{
        use                             generic-service         ; Name of service template to use
        host_name                       example-a
        service_description             Total Processes
        check_command			              check_nrpe!check_procs!250!400!RSZDT
        }
# Define a service to check the load on the example-a machine.
define service{
        use                             generic-service         ; Name of service template to use
        host_name                       example-a
        service_description             Current Load
        check_command			              check_nrpe!check_load!5.0,4.0,3.0!10.0,6.0,4.0
        }
# Define a service to check SSH on the example-a machine.
# Disable notifications for this service by default, as not all users may have SSH enabled.
define service{
        use                             generic-service         ; Name of service template to use
        host_name                       example-a
        service_description             SSH
        check_command			              check_ssh
        notifications_enabled		        0
        }
' > example-a.cfg

