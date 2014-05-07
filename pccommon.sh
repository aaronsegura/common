#
# For use by Rackspace Private Cloud team.  May safely be removed.
#
#  Report bugs to Aaron Segura x501-5895
#
echo -n "Importing Private Cloud Common Functions..."

function ix() { curl -F 'f:1=<-' http://ix.io < "${1:-/dev/stdin}"; }

function nova-hypervisor-vm-list {
mysql -e 'select instances.display_name as "Instance Name",instances.host as "Hypervisor",vm_state as State,value as flavor from instance_system_metadata left join instances on instance_system_metadata.instance_uuid=instances.uuid where instance_uuid in (select uuid from instances where deleted = 0) and `key` = "instance_type_name" order by host,value;' nova
}

function nova-hypervisor-free {
CPU_RATIO=`awk -F= '/^cpu_allocation_ratio=/ {print $2}' /etc/nova/nova.conf`

mysql -e "select hypervisor_hostname as Hypervisor,free_ram_mb as FreeMemGB,(vcpus*${CPU_RATIO})-vcpus_used as FreeVCPUs, free_disk_gb FreeDiskGB,running_vms ActiveVMs from compute_nodes where deleted = 0;" nova
}

echo "Done"
