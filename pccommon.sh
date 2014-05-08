#
# For use by Rackspace Private Cloud team.  May safely be removed.
#
#  Report bugs to Aaron Segura x501-5895.
#   1RevDrxQqJV3Z16ptEA2YtUH8G61b2qSZ
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
RAM_RATIO=`awk -F= '/^ram_allocation_ratio=/ {print $2}' /etc/nova/nova.conf`
mysql -te "select hypervisor_hostname as Hypervisor,((memory_mb*${RAM_RATIO})-memory_mb_used)/1024 as FreeMemGB,(vcpus*${CPU_RATIO})-vcpus_used as FreeVCPUs, free_disk_gb FreeDiskGB,running_vms ActiveVMs from compute_nodes where deleted = 0;" nova
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

################
echo "  - rpc-common-errors-scan() - Pretty much what it sounds like"
function rpc-common-errors-scan() {
  echo "Checking for common issues..."

  echo -n "  - MySQL Replication: "
  MYSQL_SLAVE=`mysql -e "show slave status"`
  if [ "$MYSQL_SLAVE" ]; then
    mysql -e "show slave status \G" | egrep 'Slave_(IO|SQL)_Running' | wc -l | grep 2 > /dev/null 2>&1
    [ $? -eq 0 ] && echo -n "Local Slave OK" 
  else
    echo "No Replication Configured"
  fi

  echo "  - OpenVSwitch:"
  echo "  -   Missing Taps:"
  for net in `neutron net-list | awk '/[0-9]/ {print $2}'`; do neutron dhcp-agent-list-hosting-net $net | grep True > /dev/null 2>&1; [ $? -eq 0 ] && echo "        [OK] `echo $net | rpc-filter`"; done  
  echo -n "  -   Dead Taps: "
  ovs-vsctl show | grep -A1 \"tap | egrep "tag: 4095" > /dev/null 2>&1
  [ $? -eq 0 ] && echo "Dead Taps Detected." || echo "[OK]"

  echo "  -   Bridges: "
  for bridge in `ovs-vsctl list-br | egrep 'eth|bond'`; do 
    PORTS=`ovs-vsctl list-ports $bridge | wc -l`
    if [ $PORTS -lt 2 ]; then
      echo "         [$PORTS ports] $bridge"
    else
      echo "         [OK] $bridge"
    fi
  done


  echo "  - Operating System:"
  echo -n "  -   Disk: "
  df -P -t ext2 -t ext3 -t ext4 -t xfs -t nfs | awk '{print $5}' | tr -d \% | egrep '^[0-9]+$' | egrep '^9[0-9]' > /dev/null 2>&1
  [ $? -eq 0 ] && echo "Disk reaching capacity.  Investigate" || echo "[OK]"
  echo "Done!"

}
################
echo "  - rpc-environment-scan() - Update list of internal filters"
function rpc-environment-scan() {
  echo "Scanning environment.  Please hold..."
  echo "  - Keystone"
  tenant_repl=`keystone tenant-list | awk '/[0-9]/ {print "s/"$2"/[[Tenant: "$4"]]/g;"}'`
  user_repl=`keystone user-list | awk '/[0-9]/ {print "s/"$2"/[[User: "$4"]]/g;"}'`

  `which neutron > /dev/null`
  if [ $? -eq 0 ]; then
    OS_NETCMD="neutron"
  else
    `which quantum > /dev/null`
    if [ $? -eq 0 ]; then
      OS_NETCMD="quantum"
    else
      OS_NETCMD="nova"
    fi
  fi

  echo "  - Networking ($OS_NETCMD)"

  net_repl=`nova net-list | awk '/[0-9]/ {print "s/"$2"/[[Network: "$4"]]/g;"}'`

  echo "  - Nova"
  host_repl=`nova list | awk '/[0-9]/ {print "s/"$2"/[[Instance: "$4"]]/g;"}'`
  flav_repl=`nova flavor-list | awk -F\| '/[0-9]/ {print "s/"$3"/[[Flavor: "$8"v,"$4"M,"$5"\/"$6"G,"$7"swap]]/g;"}' | tr -d " "`

  echo "  - Glance"
  img_repl=`nova image-list | awk -F\| '/[0-9]/ {gsub(/[ ]+/, "", $2);gsub(/^ /, "", $3);print "s/"$2"/[[Img: "$3"]]/g;"}'`

  echo "Done!"
}
################
echo "Done!"

echo

ip netns | grep '^vips$' > /dev/null 2>&1
[ $? -eq 0 ] && HA=1

if [ ${SKIPSCAN=0} -eq 0 ]; then
  rpc-environment-scan
  #echo
  #rpc-common-errors-scan
fi

