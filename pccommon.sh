#
# For use by Rackspace Private Cloud team.  May safely be removed.
#
#  Report bugs to Aaron Segura x501-5895
#
echo -n "Importing Private Cloud Common Functions..."

function ix() { curl -F 'f:1=<-' http://ix.io < "${1:-/dev/stdin}"; }

function nova-hypervisor-list {
mysql -e 'select instances.display_name as "Instance Name",instances.host as "Hypervisor",vm_state as State,value as flavor from instance_system_metadata left join instances on instance_system_metadata.instance_uuid=instances.uuid where instance_uuid in (select uuid from instances where deleted = 0) and `key` = "instance_type_name" order by host,value;' nova
}

echo "Done"

