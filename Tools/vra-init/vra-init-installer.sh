#!/bin/bash

echo "  ____  ___   ____________  ___  ___  ____     _________________"
echo " / __ \/ _ | / __/  _/ __/ / _ \/ _ \/ __ \__ / / __/ ___/_  __/"
echo "/ /_/ / __ |_\ \_/ /_\ \  / ___/ , _/ /_/ / // / _// /__  / /"
echo "\____/_/ |_/___/___/___/ /_/  /_/|_|\____/\___/___/\___/ /_/"
echo "         Operational Aid Source for Infra-Structure"
echo ""
echo "@author: Hye-Churn Jang, CMBU Specialist in Korea, VMware [jangh@vmware.com]"
echo ""
echo "       vRealize Automation Linux Template Setup Tool!"
echo ""


##################################################################################
# Get OS Type
##################################################################################
OS_ID=`cat /etc/os-release | grep -E "^ID=" | sed -e 's/ID=//g' | sed -e 's/"//g'`
OS_VER=`cat /etc/os-release | grep -E "^VERSION_ID=" | sed -e 's/VERSION_ID=//g' | sed -e 's/"//g'`
OS_TYPE=$OS_ID"-"$OS_VER
echo "OS_TYPE = $OS_TYPE"
case $OS_TYPE in
    "ubuntu-18.04") echo "checking supported OS ==> OK";;
    "centos-7") echo "checking supported OS ==> OK";;
    *)
        echo "checking supported OS ==> Failed"
        exit 1
        ;;
esac
echo ""


##################################################################################
# Set TimeZone
##################################################################################
function set_timezone {
    echo ""
    ls -l /usr/share/zoneinfo/ | grep -E "^d" | awk '{print " - " $9}'
    echo ""
    echo -n "select time zone category : "
    read TIME_ZONE_CAT
    if [ ! -d /usr/share/zoneinfo/$TIME_ZONE_CAT ]; then
        echo "incorrect time zone category"; return 1
    fi
    echo ""
    ls -C --color=never /usr/share/zoneinfo/$TIME_ZONE_CAT
    echo ""
    echo -n "select time zone : "
    read TIME_ZONE
    if [ ! -f /usr/share/zoneinfo/$TIME_ZONE_CAT/$TIME_ZONE ]; then
        echo "incorrect time zone"; return 1
    fi
    cp -f /usr/share/zoneinfo/$TIME_ZONE_CAT/$TIME_ZONE /etc/localtime
    echo "time zone setting finished"
    echo "" 
    return 0    
}
while true; do
    echo -n "do you want to set timezone? (y|n): "
    read KEY
    case $KEY in
        [yY]|[yY][Ee][Ss])
            while true; do
                set_timezone
                if [ $? == 0 ]; then break; fi
            done; break;;
        [nN]|[n|N][O|o]) break;;
        *) echo "incorrect input";;
    esac
done


##################################################################################
# Set Network Time
##################################################################################
function set_ntp {
    while true; do
        echo -n "input ntp address\n(example : ntp.example.com or 1.2.3.4) : "
        read NTP_SERVER
        echo -n "is correct ntp address $NTP_SERVER ? (y|n) : "
        read KEY2
        case $KEY2 in
            [yY]|[yY][Ee][Ss]) break;;
            [nN]|[n|N][O|o]) continue;;
            *) echo "incorrect input";;
        esac
    done
    case $OS_TYPE in
        "ubuntu-18.04")
            timedatectl set-ntp on
            sed -i -e '/^NTP=/d' /etc/systemd/timesyncd.conf
            echo "NTP=$NTP_SERVER" >> /etc/systemd/timesyncd.conf
            systemctl restart systemd-timesyncd
            systemctl enable systemd-timesyncd
            ;;
        "centos-7")
            timedatectl set-ntp on
            sed -i -e '/^server .*/d' /etc/chrony.conf
            echo "server $NTP_SERVER iburst" >> /etc/chrony.conf
            systemctl restart chronyd
            systemctl enable chronyd
            ;;
    esac
    echo "ntp setting finished"
    echo ""
}
while true; do
    echo -n "do you want to set ntp? (y|n): "
    read KEY
    case $KEY in
        [yY]|[yY][Ee][Ss]) set_ntp; break;;
        [nN]|[n|N][O|o]) break;;
        *) echo "incorrect input";;
    esac
done


##################################################################################
# Set Repository
##################################################################################
function set_repository {
    while true; do
        echo -n "input repository url (ex: http://repo.example.com/ubuntu or https://1.2.3.4/rhel7) : "
        read REPO_URL
        echo -n "is correct repository url $REPO_URL ? (y|n) : "
        read KEY2
        case $KEY2 in
            [yY]|[yY][Ee][Ss]) break;;
            [nN]|[n|N][O|o]) continue;;
            *) echo "incorrect input";;
        esac
    done
    case $OS_TYPE in
        "ubuntu-18.04")
            mv /etc/apt/sources.list /etc/apt/sources.list.`date +%F-%H-%M-%S`.bak
            cat <<EOF> /etc/apt/sources.list
deb $REPO_URL bionic main restricted
deb $REPO_URL bionic-updates main restricted
deb $REPO_URL bionic universe
deb $REPO_URL bionic-updates universe
deb $REPO_URL bionic multiverse
deb $REPO_URL bionic-updates multiverse
deb $REPO_URL bionic-backports main restricted universe multiverse
deb $REPO_URL bionic-security main restricted
deb $REPO_URL bionic-security universe
deb $REPO_URL bionic-security multiverse
EOF
            ;;
        "centos-7")
            mkdir -p /etc/yum.repos.bak
            mv /etc/yum.repos.d/* /etc/yum.repos.bak/
            cat <<EOF> /etc/yum.repos.d/custom.repo
[custom]
name=Custom Repository
baseurl=$REPO_URL
enabled=1
gpgcheck=0
EOF
            ;;
    esac
    echo "repository setting finished"
    echo "" 
}
while true; do
    echo -n "do you want to set repository? (y|n): "
    read KEY
    case $KEY in
        [yY]|[yY][Ee][Ss]) set_repository; break;;
        [nN]|[n|N][O|o]) break;;
        *) echo "incorrect input";;
    esac
done


##################################################################################
# Install Cloud Packages
##################################################################################
echo "install packages"
echo -n "press any key to continue (ctrl + c is exit)"
read -n 1 -s -r
echo ""
case $OS_TYPE in
    "ubuntu-18.04")
        cloud-init clean
        apt purge -f cloud-init
        rm -rf /etc/cloud
        rm -rf /var/lib/cloud
        apt update && apt upgrade -y
        apt install ifupdown resolvconf -y
        apt install -y cloud-init gdisk traceroute tcpdump python3 python3-pip
        apt purge -f nplan netplan.io
        apt autoremove -y
        ;;
    "centos-7")
        yum repolist && yum update -y
        yum install -y cloud-init gdisk traceroute tcpdump net-tools bind-utils wget git python3 python3-pip
        ;;
esac

echo "disable cloud-init service for vra-init"
systemctl disable cloud-init-local.service cloud-init.service cloud-config.service cloud-final.service

echo "finished"
echo ""


##################################################################################
# Configuration
##################################################################################
echo "configuration"
case $OS_TYPE in
    "ubuntu-18.04")
        systemctl stop systemd-networkd.socket systemd-networkd networkd-dispatcher systemd-networkd-wait-online systemd-resolved
        systemctl disable systemd-networkd.socket systemd-networkd networkd-dispatcher systemd-networkd-wait-online systemd-resolved
        systemctl mask systemd-networkd.socket systemd-networkd networkd-dispatcher systemd-networkd-wait-online systemd-resolved
        rm -rf /etc/netplan/*.yaml
        echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/99_disabled_network.cfg
        sed -i -e 's/^disable_root:.*/disable_root: false/g' /etc/cloud/cloud.cfg
        sed -i -e 's/^preserve_hostname:.*/preserve_hostname: true/g' /etc/cloud/cloud.cfg
        ;;
    "centos-7")
        systemctl disable firewalld
        systemctl stop firewalld
        systemctl disable NetworkManager
        systemctl stop NetworkManager
        yum remove -y firewalld NetworkManager
        sed -i -e 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
        echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/99_disabled_network.cfg
        sed -i -e 's/^disable_root:.*/disable_root: 0/g' /etc/cloud/cloud.cfg
        sed -i -e 's/^ssh_pwauth:.*/ssh_pwauth: 1/g' /etc/cloud/cloud.cfg
        sed -i -e 's/^disable_vmware_customization:.*//g' /etc/cloud/cloud.cfg
        echo "NOZEROCONF=yes" >> /etc/sysconfig/network
        ;;
esac

echo "finished"
echo ""


##################################################################################
# Install VRA-INIT
##################################################################################
VRA_INIT=/usr/bin/vra-init
VRA_INIT_SERVICE=/lib/systemd/system/vra-init.service
echo "install vra-init"
echo -n "press any key to continue (ctrl + c is exit)"
read -n 1 -s -r
echo ""
echo "Auto-Disk-Worker do"
echo " - auto discover new attached disk and create LVM partition with XFS format on new disk"
echo " - auto resize disk and expand LVM partition"
while true; do
    echo -n "do you want to set Auto-Disk-Worker? (y|n): "
    read KEY
    case $KEY in
        [yY]|[yY][Ee][Ss]) ADW="YES"; break;;
        [nN]|[n|N][O|o]) ADW="NO"; break;;
        *) echo "incorrect input";;
    esac
done
if [ "$ADW" == "YES" ]; then
    while true; do
        echo -n "polling frequency? (<integer>seconds, default=60) : "
        read ADW_FRQ
        if [[ $ADW_FRQ =~ ^[1-9][0-9]*$ ]] ; then
            break
        elif [ "$ADW_FRQ" == "" ]; then
            ADW_FRQ=60
            break
        else
            echo "incorrect input"
        fi
    done
else
    ADW_FRQ=60
fi

cat <<EOF> $VRA_INIT
#!/bin/bash
CHECK_NETWORK_TICK=1
CHECK_DISK_TICK=$ADW_FRQ
function _check_network {
    local DEV_NAME=\`ip link | grep "^2:" | awk '{print \$2}' | sed -e 's/://g'\`
    local GW_ADDR=\`ip route | grep default | awk '{print \$3}'\`
    local DNS_ADDR=\`cat /etc/resolv.conf | grep nameserver | awk '{print \$2}'\`
    # Check Vars
    if [ -z "\$DEV_NAME" ]; then return 1; fi
    if [ -z "\$GW_ADDR" ]; then return 1; fi
    if [ -z "\$DNS_ADDR" ]; then return 1; fi
    # Check IP address
    if [ -z "\`ip addr show dev \$DEV_NAME | grep "inet " | awk '{print \$2}' | sed -e 's/\/.\+//g'\`" ]; then return 1; fi
    # Check Gateway
    if [ "\`ping -c 1 -W 1 \$GW_ADDR 2>&1>/dev/null; echo \$?\`" != "0" ]; then return 1; fi
    # Check DNS
    if [ "\`ping -c 1 -W 1 \$DNS_ADDR 2>&1>/dev/null; echo \$?\`" != "0" ]; then return 1; fi
    return 0
}
function check_network {
    while true; do
        _check_network
        if [ \$? ==  0 ]; then break; fi
        sleep \$CHECK_NETWORK_TICK
    done
}
function format_disk {
    local DISK=\$1
    local DISK_COUNT=0
    if [ -f /etc/disk.count ]; then DISK_COUNT=\`cat /etc/disk.count\`; fi
    DISK_COUNT=\`expr \$DISK_COUNT + 1\`
    parted \$DISK --script mklabel gpt
    parted \$DISK --script mkpart primary 0% 100%
    parted \$DISK --script set 1 lvm on
    pvcreate \$DISK"1"
    vgcreate disk\$DISK_COUNT \$DISK"1"
    lvcreate -l 100%VG -n volume disk\$DISK_COUNT
    mkfs.xfs -f /dev/disk\$DISK_COUNT/volume
    echo \$DISK_COUNT > /etc/disk.count
    echo "/dev/disk\$DISK_COUNT/vol" >> /etc/disk.list
    echo \$DISK | sed -e 's/\/dev\///g' >> /etc/disk.dev
}
function resize_disk {
    local DISK=\$1
    local VG_NAME=\`pvdisplay | grep -A 1 \$DISK | grep "VG Name" | awk '{print \$3}'\`
    sgdisk -e \$DISK
    parted \$DISK --script resizepart 1 100%
    pvresize \$DISK"1"
    lvresize -l 100%VG /dev/\$VG_NAME/volume
    mkdir -p /tmp/.disk_resize/\$VG_NAME
    mount /dev/\$VG_NAME/volume /tmp/.disk_resize/\$VG_NAME
    xfs_growfs /dev/\$VG_NAME/volume
    umount /tmp/.disk_resize/\$VG_NAME
}
function arrange_disk {
    for HOST in /sys/class/scsi_host/*; do echo "- - -" > \$HOST/scan; done
    for DISK in \`cat /etc/disk.dev 2>/dev/null\`; do echo 1 > /sys/class/block/\$DISK/device/rescan; done
    local FDISK=""
    for DISK in \`fdisk -l 2>&1 | grep "Disk" | grep '/dev/sd' | awk '{print \$2}' | grep -v sda | sed -e 's/://g'\`; do
        FDISK=\`fdisk -l \$DISK 2>&1\`
        if [ -z "\`echo "\$FDISK" | grep "primary"\`" ]; then format_disk \$DISK 2>&1 >/var/log/vmware-vmsvc.log; fi
        if [ -n "\`echo "\$FDISK" | grep "GPT PMBR size mismatch"\`" ]; then resize_disk \$DISK 2>&1 >/var/log/vmware-vmsvc.log; fi
    done
}
function _check_disk {
    while true; do
        arrange_disk
        sleep \$CHECK_DISK_TICK
    done
}
function check_disk {
    _check_disk 2>&1 >/dev/null &
}
function _start_cloud_init {
    /usr/bin/cloud-init init --local
    /usr/bin/cloud-init init
    /usr/bin/cloud-init modules --mode=config
    /usr/bin/cloud-init modules --mode=final
}
function start_cloud_init {
	_start_cloud_init 2>&1 >/var/log/cloud-init.log &
}

EOF

if [ "$ADW" == "YES" ]; then
    echo "arrange_disk" >> $VRA_INIT
fi
cat <<EOF>> $VRA_INIT
check_network
start_cloud_init
EOF
if [ "$ADW" == "YES" ]; then
    echo "check_disk" >> $VRA_INIT
fi
chmod 755 $VRA_INIT

echo "register systemd service"
cat <<EOF> $VRA_INIT_SERVICE
[Unit]
Description=vRealize Automation Init Service
After=vmware-tools.service

[Service]
Type=oneshot
ExecStart=/usr/bin/vra-init
RemainAfterExit=yes
TimeoutSec=0
KillMode=process
TasksMax=infinity
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
EOF

while true; do
    echo -n "do you want to set enable vra-init? (y|n): "
    read KEY
    case $KEY in
        [yY]|[yY][Ee][Ss])
            systemctl daemon-reload
            systemctl enable vra-init.service
            ;;
        [nN]|[n|N][O|o]) break;;
        *) echo "incorrect input";;
    esac
done

echo "finished"
echo ""


##################################################################################
# Remove Temp Files
##################################################################################
echo "remove temp files"
rm -rf /tmp/*
rm -rf /var/log/cloud-*
rm -rf /var/log/vmware-*.*
rm -rf /root/.bash_history
echo "finished"
echo ""


echo "   _____  __   ________  __  _   _____  ___     __"
echo "  / __/ |/ /_ / / __ \ \/ / | | / / _ \/ _ |   / /"
echo " / _//    / // / /_/ /\  /  | |/ / , _/ __ |  /_/"
echo "/___/_/|_/\___/\____/ /_/   |___/_/|_/_/ |_| (_)"
echo ""
