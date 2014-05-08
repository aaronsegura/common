#
# For use by Rackspace Private Cloud team.  May safely be removed.
#
#  Report bugs to Aaron Segura x501-5895
#

echo
echo "Importing Private Cloud Common Functions..."

################
echo "  - ix() - Quickly post things to ix.io"
function ix() { curl -F 'f:1=<-' http://ix.io < "${1:-/dev/stdin}"; }

################
echo "  - rpc-hypervisor-vms() - Display all hypervisors and associated instances"
function rpc-hypervisor-vms {
mysql -te 'select host as "Hypervisor", instances.display_name as "Instance Name",image_ref as "Image", vm_state as State, vcpus as "VCPUs", memory_mb as "RAM", root_gb as "Root", ephemeral_gb as "Ephem" from instance_system_metadata left join instances on instance_system_metadata.instance_uuid=instances.uuid where instance_uuid in (select uuid from instances where deleted = 0) and `key` = "instance_type_name" order by host,display_name' nova
}

################
echo "  - rpc-hypervisor-free() - Display free resources on each Hypervisor, as reported by MySQL"
function rpc-hypervisor-free {
CPU_RATIO=`awk -F= '/^cpu_allocation_ratio=/ {print $2}' /etc/nova/nova.conf`
mysql -te "select hypervisor_hostname as Hypervisor,free_ram_mb as FreeMem,(vcpus*${CPU_RATIO})-vcpus_used as FreeVCPUs, free_disk_gb FreeDiskGB,running_vms ActiveVMs from compute_nodes where deleted = 0;" nova
}

################
echo "  - rpc-filter() - Replace stinky UUIDs with refreshing descriptive names inline"
function rpc-filter {
  replist=`echo ${tenant_repl}${host_repl}${net_repl}${flav_repl}${img_repl}${user_repl} | tr -d "\n"`

  OLDIFS=$IFS
  IFS=''

  while read inputs; do
    echo $inputs | sed -e "${replist}"
  done

  IFS=$OLDIFS
}

echo "  - rpc-environment-scan() - Update list of internal filters"
function rpc-environment-scan() {
  echo "Scanning environment.  Please hold..."
  echo "  - Keystone"
  tenant_repl=`keystone tenant-list | awk '/[0-9]/ {print "s/"$2"/[["$4" Tenant]]/g;"}'`
  user_repl=`keystone user-list | awk '/[0-9]/ {print "s/"$2"/[["$4" User]]/g;"}'`

  `which neutron > /dev/null`
  if [ $? -eq 0 ]; then
    OS_NETCMD="neutron"
  else
    `which quantum > /dev/null`
    if [ $? -eq 0]; then
      OS_NETCMD="quantum"
    else
      OS_NETCMD="nova"
    fi
  fi

  echo "  - Networking ($OS_NETCMD)"

  net_repl=`nova net-list | awk '/[0-9]/ {print "s/"$2"/[["$4" Network]]/g;"}'`

  echo "  - Nova"
  host_repl=`nova list | awk '/[0-9]/ {print "s/"$2"/[["$4" Instance]]/g;"}'`
  flav_repl=`nova flavor-list | awk -F\| '/[0-9]/ {print "s/"$3"/[["$8"v,"$4"M,"$5"\/"$6"G,"$7"swap Flavor]]/g;"}' | tr -d " "`

  echo "  - Glance"
  img_repl=`nova image-list | awk -F\| '/[0-9]/ {gsub(/[ ]+/, "", $2);gsub(/^ /, "", $3);print "s/"$2"/[["$3" Image]]/g;"}'`

  echo "Done!"
}
################

echo "Done!"

echo

if [ ${SKIPSCAN=0} -eq 0 ]; then
  rpc-environment-scan
fi

