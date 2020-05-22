<pre>
<h3>1. Create Master Template</h3>

<b>1.1 Create VM</b>

Optional Setting
CPU Hot Plug
Mem Hot Plug
Disk with Thin provisioning
Install Ubuntu 18

<b>1.2 Set default configuration</b>

Login User Account
$ sudo -i
$ passwd
Logout All
Login Root Account
$ userdel <USER_ACCOUNT>
$ rm -rf /home/<USER_ACCOUNT> 
$ vi /etc/ssh/sshd_config
PermitRootLogin yes
$ systemctl restart ssh
$ poweroff
Remove VM's Install Media at vCenter
Start VM
Option: Copy Public SSL Key to /root/.ssh/authorized_keys
$ cp /usr/share/zoneinfo/Asia/Seoul /etc/localtime
$ vi /etc/systemd/timesyncd.conf
NTP=<NTP_SERVER_ADDRESS>
$ systemctl restart systemd-timesyncd
$ apt update && apt upgrade -y
$ apt install -y traceroute tcpdump python3 python3-pip
$ systemctl stop cloud-init-local cloud-init cloud-config cloud-final ufw open-vm-tools
$ apt purge -f cloud-init ufw open-vm-tools
$ apt autoremove -y
$ rm -rf /etc/cloud /var/lib/cloud
Install VMware Tools, VMware Official Recommended
$ apt install -y cloud-init
$ systemctl disable cloud-init-local cloud-init cloud-config cloud-final
$ vi /etc/cloud/cloud.cfg
disable_root: false
preserve_hostname: true
package_mirrors:
  - archies: [i386, amd64]
    failsafe:
      primary: <REPO_URL>
      security: <REPO_URL>
$ vi /etc/cloud/cloud.cfg.d/99_network_disabled.cfg
network: {config: disabled}

<b>1.3 Install vra-init</b>

Copy vra-init batch file to /usr/bin/vra-init
$ chmod 755 /usr/bin/vra-init
Copy vra-init.service to /lib/systemd/system/vra-init.service
$ systemctl disable vra-init

<b>1.4 Make Fresh</b>

$ cd /var/log
$ rm -rf vmware-*
$ rm -rf cloud-init*
$ rm -rf alternatives.log auth.log bootstrap.log dpkg.log faillog kern.log lastlog syslog tallylog
$ rm -rf /root/.bash_history
$ rm -rf /tmp/*
$ rm -rf /etc/netplan/*.yaml
$ poweroff

<b>1.5 Change VM to Template at vCenter</b>

<h3>2. Create Working Template for VRA</h3>

<b>2.1 Config VM</b>

Clone Master Template to Working VM
Delete All Network Adapters
Start VM

<b>2.2 Set enable vra-init service</b>

$ systemctl enable vra-init

<b>2.3 Make Fresh</b>

$ cd /var/log
$ rm -rf vmware-*
$ rm -rf alternatives.log auth.log bootstrap.log dpkg.log faillog kern.log lastlog syslog tallylog
$ rm -rf /root/.bash_history
$ rm -rf /tmp/*
$ poweroff

<b>2.4 Change VM to Template at vCenter</b>
</pre>
