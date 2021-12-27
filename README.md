# Install the OpenShift (OKD) 4.X cluster (UPI/"bare-metal")

<img src="./img/okd-panda-flat_rocketeer_with_number.svg" height="800">

The OKD is a distribution of Kubernetes optimized for continuous application development and multi-tenant deployment. It adds developer and operations-centric tools on top of Kubernetes to enable rapid application development, easy deployment and scaling, and long-term lifecycle maintenance for small and large teams. It incorporates and extends Kubernetes with security and other integrated concepts. The OKD is a sibling Kubernetes distribution to Red Hat OpenShift. 

[Ref(s).: https://www.okd.io/#v4 ]

## IMPORTANT things to know before getting started and some facts about OpenShift (OKD) 4.X

This guide is directed to a User-Provisioned Infrastructure (UPI) built on top of KVM, but about KVM we will only cover the most crucial points or those that generate more doubts in the process. However, with some adaptations we can use this guide with any hypervisor or even physical machines (real "bare-metal"). While we can't talk about "bare-metal" for a UPI built on a hypervisor, we'll agree to use this terminology just for the sake of convenience.

The virtual machines (guests) that will be created will need to have access to Hardware Virtualization Support or Hardware-Assisted Virtualization - basically Intel's VT-x or AMD's AMD-V - as we are going to work with virtual machines that will perform some "Nested Virtualization". Therefore the hypervisor (host) in question needs to provide the virtual machines (guest) with access to the Hardware Virtualization Support.

The OpenShift (OKD) is a memory-consuming beast. It is a cluster to run and manage other systems and, presumably, with performance. It contains a series of auxiliary services related to the administration, control and management of these systems. For the cluster install and work it needs the minimum hardware requirements informed in the table below ("Minimum hardware requirements..."). If you don't have these minimal requirements stop here and don't waste your time. These resources are the minimum possible for the cluster works. Without these the cluster will not install. Without the required amount of memory will not possible for the cluster to raise all its necessary resources and a myriad of errors will occur.

Another point that must be addressed at the first moment is the base domain used by OpenShift (OKD) that must be the same internally (LAN) and externally (WAN). In other words, don't expect to install OpenShift (OKD) using the domain "myinternaldomain.org" (LAN) and access its web resources on the internet (WAN) via the domain "mywebdomain.net". Also note that the base domain used to install the cluster cannot be changed. We've already told to the OpenShift (OKD)'s development team - including the development lead - that this is an important limitation and that it can become something dramatic in the case of certain maintenances or changes. Full information about this limitation can be found at "OpenShift/OKD cluster - Use with external/outside domain" ( https://github.com/openshift/okd/discussions/716#discussioncomment-991328 ).

Keep in mind that using and running a cluster is something the the vast majority of people are not used to dealing with. So, don't expect that a cluster will work like the multithread and/or multiprocess systems that you might be used to. The cluster bootstrap process is a bit difficult and can fail even if you do all the setup correctly. Things are naturally more complex to handle and sometimes to use.

The OpenShift (OKD) is a good solution, but despite all the Red Hat hype (Red Hat OpenShift, specifically), it still needs to be matured and still has a way to go as free software, as a community and as a product (Are all these absurd RAM requirements just for running the cluster really necessary or is it simply lack of cluster optimization?). Be aware that OpenShift (OKD) 4.X is not yet widely adopted by the open source community (help can be difficult to find) and is ultimately something centered on the Red Hat universe. So, if you look at Red Hat's open source policy for OpenShift (OKD) with certain suspicion at this point, you're probably right... Finally, we don't usually trust and recommend open source products that aren't good and reliable free products and widely adopted by free software communities. Therefore, if you want to venture out with OpenShift (OKD), do it at your own risk.

In our experience using OpenShift (OKD) it showed constant instability and was incapable to be used by us in production. We don't know what the behavior of this platform would be using absurdly high hardware resources and high performance hardware, which in this scenario would prove to be, compared to others, an expensive and inefficient solution. We also noticed that some crucial documentation and official help channels are vague, incomplete, or out of date (including Red Hat OpenShift). Information and help to any problem is very difficult to obtain.

We see that this project seems to us disconnected from the large public and the free software community that is the mother cell of any serious project based largely on free software. The free software community cannot be seen as a nuisance or a problem, if it is seen as a problem then there really is a problem. This is what experience teaches us and what is here https://www.redhat.com/en ("Red Hat - We make open source technologies for the enterprise"), after all, there is no reason to talk about open source if not there is involvement of free software communities. It would be nonsense.

We need to make it clear that our intention is not to disqualify the OpenShift (OKD) project nor the work of the people involved in it, much less foment conflicts, we want to present another vision. These conclusions were built through our experience for months with this product. We are convinced that our vision does not reflect the vision of the few, but that of the many, it is up to the project leaders to define a good path for the project.

Install OpenShift (OKD) on an UPI is a long process with a lot of pitfalls and details. You need, also, some knowledge regarding network infrastructure among other things (DNS, DHCP, load balancing, etc...). Also note that hostnames and domains (DNS, basically) are critical for the functioning of the cluster and if there are any error in these configurations the cluster will not even install.

**Unfortunately, there is no easy way to deploy this thing and sometimes this process - without the correct information and without help from the community - is hard as hell...** We made this guide because we found several difficulty points in installing OpenShift (OKD) and the guides we found on the internet are complex and omit important and crucial information about this process.

**So, stay on that track and don't look back! Let's work!**

**Minimum hardware requirements...**

```
.----------------------------------------------------------------------.
| 1 X BOOTSTRAP NODE -------------- 4~8 CPU 8192~16384 RAM 60 GB DISK  |
| 3 X MASTER NODES ---------------- 4~8 CPU 8192~16384 RAM 25 GB DISK  |
| 2 X WORKER NODES ---------------- 4~8 CPU 12288~16384 RAM 30 GB DISK |
| 1 X SERVICES SERVER ------------- 4 CPU 4096 RAM 60 GB DISK          |
'----------------------------------------------------------------------'
```

**IMPORTANT:** More RAM the nodes have, better the cluster will work. The amounts of RAM above are the strictly necessary for the cluster works.

# Cluster overview

**Virtual machines...**

```
.----------------------------------------------------------------------------------------------------.
| NAME           ROLE                   OS             CPU   RAM  DISK  IP(OKD)    MAC(OKD)          |
| OKD_SERVICES   (DNS/DHCP/GW/LB/       CentOS 8       4[V]  4    60    10.3.0.3   52:54:00:3a:fd:a2 |
|                 NTP/NFS/WEB/CIA)              (IP(INT) / MAC(INT) | 10.2.0.18 / 52:54:00:92:ce:78) |
| OKD_MASTER_1   master                 Fedora CoreOS  4[V]  8    25    10.3.0.4   52:54:00:7d:97:70 |
| OKD_MASTER_2   master                 Fedora CoreOS  4[V]  8    25    10.3.0.5   52:54:00:6e:52:85 |
| OKD_MASTER_3   master                 Fedora CoreOS  4[V]  8    25    10.3.0.6   52:54:00:a3:65:d9 |
| OKD_WORKER_1   worker                 Fedora CoreOS  4[V]  12   30    10.3.0.12  52:54:00:e3:7c:fb |
| OKD_WORKER_2   worker                 Fedora CoreOS  4[V]  12   30    10.3.0.13  52:54:00:20:ec:4f |
| OKD_BOOTSTRAP  bootstrap              Fedora CoreOS  4[V]  8    60    10.3.0.19  52:54:00:07:80:62 |
'----------------------------------------------------------------------------------------------------'
```

**NOTES:** In addition to the various tests we did to define the machine settings above we tried to base it on the default KubeInit settings (inventory file) and the "Quickstart Guide: Installing OpenShift Container Platform on Red Hat Virtualization" (page 5).

[Ref(s).: https://access.redhat.com/sites/default/files/attachments/quickstart_guide_for_installing_ocp_on_rhv_1.4.pdf (page 5),
https://github.com/Kubeinit/kubeinit/blob/main/kubeinit/hosts/okd/inventory ,
https://github.com/openshift/okd/issues/152#issue-601258355 ]

Hardware requirements and other information...

 * TOTAL DISK - 60+25+25+25+30+30+60 = 255GB (195GB without OKD_BOOTSTRAP);
 * TOTAL RAM - 8+8+8+8+12+12+4 = 60GB (52GB without OKD_BOOTSTRAP);
 * RAM and DISK are in gigabytes (GB);
 * CPU is a shared resource;
 * V - Nested Virtualization required.

**NOTE:** The bootstrap node (OKD_BOOTSTRAP) is only used during the OKD installation and will be destroyed at the end of the installation.

[Ref(s).: https://docs.openshift.com/container-platform/4.2/architecture/architecture-installation.html ]

**Some acronyms...**
 * DNS - Domain Name System;
 * DHCP - Dynamic Host Configuration Protocol;
 * GW - Gateway;
 * LB - Load Balancing;
 * NTP - Network Time Protocol;
 * NFS - Network File Sharing;
 * WEB - Web server;
 * CIA - Cluster Installation and Administration.

**NOTE:** The first IP ("10.3.0.1") is by default reserved for the (KVM) hypervisor.

**IMPORTANT:** There are defined names for the services server and the nodes in the DNS, DHCP and LB settings. We do not recommend modifying these names. However, if you can't resist changing these names, just change the names referring to the services server and nodes.

**Network configuration X tags used in this documentation...**

```
.--------------------------------------------------------------------------------------------------.
| 10.3.0.3 -- 52:54:00:3a:fd:a2  X  <OKD_LAN_24>.<OKD_SERVICES_LST_OCT> ---- <OKD_SERVICES_MAC>    |
| 10.2.0.18 - 52:54:00:92:ce:78  X  <INT_LAN_24>.<OKD_SERVICES_IL_LST_OCT> - <OKD_SERVICES_IL_MAC> |
| 10.3.0.4 -- 52:54:00:7d:97:70  X  <OKD_LAN_24>.<OKD_MASTER_1_LST_OCT> ---- <OKD_MASTER_1_MAC>    |
| 10.3.0.5 -- 52:54:00:6e:52:85  X  <OKD_LAN_24>.<OKD_MASTER_2_LST_OCT> ---- <OKD_MASTER_2_MAC>    |
| 10.3.0.6 -- 52:54:00:a3:65:d9  X  <OKD_LAN_24>.<OKD_MASTER_3_LST_OCT> ---- <OKD_MASTER_3_MAC>    |
| 10.3.0.12 - 52:54:00:e3:7c:fb  X  <OKD_LAN_24>.<OKD_WORKER_1_LST_OCT> ---- <OKD_WORKER_1_MAC>    |
| 10.3.0.13 - 52:54:00:20:ec:4f  X  <OKD_LAN_24>.<OKD_WORKER_2_LST_OCT> ---- <OKD_WORKER_2_MAC>    |
| 10.3.0.19 - 52:54:00:07:80:62  X  <OKD_LAN_24>.<OKD_BOOTSTRAP_LST_OCT> --- <OKD_BOOTSTRAP_MAC>   |
'--------------------------------------------------------------------------------------------------'
```

 * "_LST_OCT" - Last Octet;
 * "_MAC" - MAC address;
 * "_IL" - Internet Lan.

**Network layout...**

```
.---------------------------------------------------------------------------.
|                  N_INT_LAN(WAN)(R_DHCP)  (10.2.0.0/24)(<INT_LAN_24>.0/24) |
|                   ↕                                                       |
|                  I_INT_LAN(WAN)                                           |
|                V_OKD_SERVICES(R_DHCP)(R_GATEWAY)                          |
|                  I_OKD_LAN(LAN)                                           |
|                   ↕                                                       |
|                  N_OKD_LAN(LAN)  (10.3.0.0/24)(<OKD_LAN_24>.0/24)         |
|                   ↕                                                       |
|  ..................................                                       |
|  ↕                ↕               ↕                                       |
| V_OKD_BOOTSTRAP  V_OKD_MASTER_1  V_OKD_WORKER_1                           |
|                  V_OKD_MASTER_2  V_OKD_WORKER_2                           |
|                  V_OKD_MASTER_3                                           |
'---------------------------------------------------------------------------'
```

 * N - Network;
 * R - Network Resource;
 * I - Network Interface Controller;
 * V - Virtual Machine.

[Ref(s).: https://www.alt-codes.net/arrow_alt_codes.php ]

**NOTES:**
 1. The N_INT_LAN is (normally) also the "default" network and N_OKD_LAN is also the "okd_network" network; 
 2. The N_INT_LAN is (normally) a NAT network with communication with the internet (WAN) and the hypervisor (host);
 3. The N_OKD_LAN is a private/isolated network without communication with the internet (WAN) and the hypervisor (host). All external communication will be done through the gateway established in the OKD_SERVICES via the network N_INT_LAN.

# Create a "very private"/"very isolated" network on KVM (N_OKD_LAN) (HYPERVISOR)

The cluster will use a private/isolated network without communication with the internet (WAN) and the hypervisor (host). All external communication will be done through the gateway (OKD_SERVICES).

The procedures required to create this network on the hypervisor (host) are in the "KVM network - Create a \"very private\"/\"very isolated\" network" section.

# Create the OKD_SERVICES server

## Create the virtual machine (HYPERVISOR)

Provides DNS, DHCP, gateway, load balancing, NTP, NFS, web server and cluster installation and administration.

Download a CentOS 8 ISO...

**NOTE:** This resource can be found here https://www.centos.org/download/ in the "CentOS Linux" section, "8 (XXXX)" tab and "x86_64" link.

MODEL

```
wget http://<MIRROR_URL>/centos/8/isos/x86_64/CentOS-<LAST_CENTOS8_VER>-x86_64-boot.iso
```

EXAMPLE

```
wget http://mirrors.mit.edu/centos/8/isos/x86_64/CentOS-8.4.2105-x86_64-boot.iso
```

**TIPS:**
 1. Choose "boot" version;
 2. Choose a mirror close to your geographic location for better download performance.

[Ref(s).: https://serverfault.com/a/1011659/276753 ]

Enable Nested Virtualization. For more details see the section "KVM Nested Virtualization - Virtualization Support or Hardware-Assisted Virtualization for guests".

It must have access to N_INT_LAN ("default") and N_OKD_LAN ("okd_network") networks. See "Network layout..." for more details.

## Install operating system (OKD_SERVICES)

Installation can be done according to the following...

* "WELCOME TO CENTOS LINUX 8" screen.
    * In "What language would you like to use during the installation process?" make sure "English" is selected in the first list and "English (United States)" is selected in the second - or those of your choice, obviously.
    * Click on "Continue".
* "INSTALLATION SUMMARY" screen.
    * Click on "Installation Destination" ("SYSTEM").
        * Probably the disk available under "Local Standard Disks" will already be selected (marked with a "V").
        * In "Storage Configuration" choose "Custom".
        * Click on "Done".
        * "MANUAL PARTITIONING" screen.
            * Check if for "New mount points will use the following partitioning scheme:" informs "LVM".
            * Click on "Click here to create them automatically."
                * Select the "/home" partition and click "-" to delete it.
                * Select the "/" partition and under "Desired Capacity:" and enter the double of the disk capacity (in reality any value above its capacity).
                    * **NOTE:** The procedure above causes the installer to use all unoccupied disk space for the selected partition. [Ref(s).: https://docs.centos.org/en-US/8-docs/standard-install/assembly_graphical-installation/ ]
                * Click on "Done".
                    * A message box ("SUMMARY OF CHANGES") will appear.
                    * Click on "Accept Changes".
    * Click on "Network & Host Name" ("SYSTEM").
        * Select the first network interface ("Ethernet (ens3)" probably) and click the "OFF" button then it will be "ON".
            * NOTE: The interface above is the NIC ens3 (I_INT_LAN) that obtain its settings from the DHCP on the network N_INT_LAN (10.2.0.0/24)(<INT_LAN_24>.0/24), therefore perform the needed configuration in its DHCP. If you don't use DHCP then you will have to configure these settings locally (manually). See "Network layout..." for more details.
        * Select the second network interface ("Ethernet (ens4)" probably) and click the "OFF" button then it will be "ON".
        * Click on "Done".
    * Click on "Software Selection" ("SOFTWARE").
        * **NOTE:** May be necessary to wait a while for the status of this option change once the network interfaces have been enabled.
        * Select "Minimal Install".
        * Click on "Done".
    * Click on "Keyboard" ("LOCALIZATION").
        * **NOTE:** Do this step only if you need adjust the layout of your keyboard.
        * Click on "+".
        * A message box ("ADD A KEYBOARD LAYOUT") will appear.
            * Select "Portuguese (Brazil)" - or one of your choice, obviously.
            * Click on "Add".
        * Select "Portuguese (Brazil)" from the list and click "^" to put it as the first option - or one of your choice, obviously.
        * Click on "Done".
    * Click on "Root Password" ("USER SETTINGS").
        * Enter the "Root Password:" and "Confirm:".
        * Click on "Done" (twice if necessary).
    * Click on "Begin Installation".
        * When finished click on "Reboot System".

After the reboot configure the OKD_SERVICES to use its hard disk at boot, that is, disable ISO as boot option.

## Network configuration (OKD_SERVICES)

Access the virtual machine's terminal.

Adjust the NIC ens3 (I_INT_LAN) to use a minimal setup...

MODEL

```
read -r -d '' FILE_CONTENT << 'HEREDOC'
BEGIN
BOOTPROTO=dhcp
DEVICE=<I_INT_LAN>
IPV6INIT=no
ONBOOT=yes
ZONE=public

END
HEREDOC
echo -n "${FILE_CONTENT:6:-3}" > '/etc/sysconfig/network-scripts/ifcfg-<INTERFACE_NAME>'
```

EXAMPLE

```
read -r -d '' FILE_CONTENT << 'HEREDOC'
BEGIN
BOOTPROTO=dhcp
DEVICE=ens3
IPV6INIT=no
ONBOOT=yes
ZONE=public

END
HEREDOC
echo -n "${FILE_CONTENT:6:-3}" > '/etc/sysconfig/network-scripts/ifcfg-ens3'
```

**NOTE:** If you haven't done it already, make the appropriate DHCP settings for the NIC ens3 (I_INT_LAN). If you don't use DHCP then you will have to configure these settings locally (manually). See "Network layout..." for more details.

Define a hostname and a domain locally for the server...

MODEL

```
echo "127.0.0.1   okd-services.<YOUR_DOMAIN> okd-services" | tee -a /etc/hosts > /dev/null 2>&1
echo "HOSTNAME=okd-services" | tee -a /etc/sysconfig/network > /dev/null 2>&1
hostnamectl set-hostname "okd-services" --static
```

EXAMPLE

```
echo "127.0.0.1   okd-services.domain.abc okd-services" | tee -a /etc/hosts > /dev/null 2>&1
echo "HOSTNAME=okd-services" | tee -a /etc/sysconfig/network > /dev/null 2>&1
hostnamectl set-hostname "okd-services" --static
```

**NOTE:** If the N_INT_LAN ("default") network has a local DNS these settings may be different.

[Ref(s).: https://unix.stackexchange.com/a/239950/61742 ]

Restart the server...

```
reboot
```

 ## Install the "epel-release" resources and update the OS (OKD_SERVICES)

```
dnf install -y epel-release
dnf update -y
```

 ## Clone the "okd_bare_metal" repository and configure its resources (OKD_SERVICES)

This repository contains configuration files for OpenShift (OKD) (configuration/bootstrap files), ISC BIND 9 (DNS service), ISC DHCP Server (DHCP service), "chrony" (NTP clients) and HAProxy (load balancer service).

Clone the "okd_bare_metal" repository...

```
dnf install -y git-core
cd "/usr/local/src"
git clone https://github.com/eduardolucioac/okd_bare_metal.git
```

Open the "setup.bash" script file...

```
vi "/usr/local/src/okd_bare_metal/setup.bash"
```

... , configure the parameters in the "SETUP PARAMETERS" section according to your reality and according to its guidelines...

```
[...]
# > -------------------
# SETUP PARAMETERS

# The domain for the OpenShift (OKD) cluster.
# IMPORTANT: The domain used to install the cluster CANNOT BE CHANGED! See documentation!
# By Questor
OKD_DOMAIN="domain.abc"

# First 3 octets of OpenShift (OKD) cluster network (forward and reverse).
OKD_LAN_24="10.3.0"
OKD_LAN_24_REVERSE="0.3.10"

# Last octet of the OKD_SERVICES server IP and its MAC address.
OKD_SERVICES_LST_OCT="3"

# Last octet of the OKD_BOOTSTRAP node IP and its MAC address.
OKD_BOOTSTRAP_LST_OCT="19"
OKD_BOOTSTRAP_MAC="52:54:00:07:80:62"

# Last octet of the OKD_MASTER_1 node IP and its MAC address.
OKD_MASTER_1_LST_OCT="4"
OKD_MASTER_1_MAC="52:54:00:7d:97:70"

# Last octet of the OKD_MASTER_2 node IP and its MAC address.
OKD_MASTER_2_LST_OCT="5"
OKD_MASTER_2_MAC="52:54:00:6e:52:85"

# Last octet of the OKD_MASTER_3 node IP and its MAC address.
OKD_MASTER_3_LST_OCT="6"
OKD_MASTER_3_MAC="52:54:00:a3:65:d9"

# Last octet of the OKD_WORKER_1 node IP and its MAC address.
OKD_WORKER_1_LST_OCT="12"
OKD_WORKER_1_MAC="52:54:00:e3:7c:fb"

# Last octet of the OKD_WORKER_2 node IP and its MAC address.
OKD_WORKER_2_LST_OCT="13"
OKD_WORKER_2_MAC="52:54:00:20:ec:4f"

# NOTES:
# I - In case you want to add new master or worker nodes, in the examples above we
# left a gap for 5 sequential IPs for new master nodes (last octets 7, 8, 9, 10 and
# 11) and a gap for 5 sequential IPs for new worker nodes (last octets 14, 15, 16,
# 17 and 18);
# II - All network settings refer to OpenShift (OKD) cluster network ([N]OKD_LAN).
# By Questor

# Available disk space (in GB) for OKD_SERVICES server minus 15. E.g.: 60-15=45.
OKD_SERVICES_STRG_SZ="45"

# < -------------------
[...]
```

... , execute the script file with this command...

```
cd "/usr/local/src/okd_bare_metal"
bash setup.bash
```

... and it will automatically configure all its resources.

**TIP:** To obtain the values for the "OKD_VM_NAME_MAC" parameters you can pre-prepare the virtual machines (guests), that is, just provision the hardware resources on the hypervisor (host) without install anything. Or, you can generate new ones at the URL https://miniwebtool.com/mac-address-generator/ using MAC address prefix "52:54:00" (is always the same for KVM), MAC address format with ":" and case "Lowercase". Then use these MAC addresses when creating the virtual machines (guests).

## Setup the gateway (OKD_SERVICES)

As the N_OKD_LAN network does not allow outbound network traffic (WAN, internet), so we need to configure OKD_SERVICES to works as a gateway for the servers that are on this network.

Enable "IP forwarding"...

```
tee "/etc/sysctl.d/ip_forward.conf" << EOF
net.ipv4.ip_forward=1
EOF
sysctl -w net.ipv4.ip_forward=1
```

Setup an outbound NAT gateway with destination on NIC ens3 (<I_INT_LAN>) masking devices attached on NIC ens4 (<I_OKD_LAN>)...

MODEL

```
firewall-cmd --permanent --zone public --add-masquerade
firewall-cmd --permanent --direct --add-rule ipv4 nat POSTROUTING 0 -o <I_INT_LAN> -j MASQUERADE
firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i <I_OKD_LAN> -o <I_INT_LAN> -j ACCEPT
firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i <I_INT_LAN> -o <I_OKD_LAN> -m state --state RELATED,ESTABLISHED -j ACCEPT
firewall-cmd --reload
```

EXAMPLE

```
firewall-cmd --permanent --zone public --add-masquerade
firewall-cmd --permanent --direct --add-rule ipv4 nat POSTROUTING 0 -o ens3 -j MASQUERADE
firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i ens4 -o ens3 -j ACCEPT
firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i ens3 -o ens4 -m state --state RELATED,ESTABLISHED -j ACCEPT
firewall-cmd --reload
```

[Ref(s).: https://superuser.com/a/1659586/195840 ,
https://devops.ionos.com/tutorials/deploy-outbound-nat-gateway-on-centos-7/ ,
https://www.server-world.info/en/note?os=CentOS_Stream_8&p=firewalld&f=2 ,
https://www.comdivision.com/blog/centos-7-nat-router-basic-configuration ,
https://blog.redbranch.net/2015/07/30/centos-7-as-nat-gateway-for-private-network/ .
https://unix.stackexchange.com/a/550064/61742 ,
https://forums.centos.org/viewtopic.php?t=53819#p227743 ,
https://www.server-world.info/en/note?os=CentOS_7&p=firewalld&f=2 ,
https://serverfault.com/q/870902/276753 ]

## Setup the DHCP service (ISC DHCP service) (OKD_SERVICES)

Install the package...

```
dnf install -y dhcp-server
```

Create a static network configuration for the NIC ens4 (<I_OKD_LAN>) as the DHCP service will be bound to it...

MODEL

```
read -r -d '' FILE_CONTENT << 'HEREDOC'
BEGIN
BOOTPROTO=static
ONBOOT=yes
DEVICE=<I_OKD_LAN>
IPADDR=<OKD_LAN_24>.<OKD_SERVICES_LST_OCT>
NETMASK=255.255.255.0
ZONE=public
IPV6INIT=no

END
HEREDOC
echo -n "${FILE_CONTENT:6:-3}" > '/etc/sysconfig/network-scripts/ifcfg-<I_OKD_LAN>'
```

EXAMPLE

```
read -r -d '' FILE_CONTENT << 'HEREDOC'
BEGIN
BOOTPROTO=static
ONBOOT=yes
DEVICE=ens4
IPADDR=10.3.0.3
NETMASK=255.255.255.0
ZONE=public
IPV6INIT=no

END
HEREDOC
echo -n "${FILE_CONTENT:6:-3}" > '/etc/sysconfig/network-scripts/ifcfg-ens4'
```

Restart the network service...

```
systemctl restart NetworkManager.service
```

Copy the "dhcpd.conf" DHCP configuration file...

```
cd "/usr/local/src/okd_bare_metal"
mv /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf_BAK
cp ./dhcpd.conf /etc/dhcp/
```

**NOTE:** The DHCP service will be active only on the interface that is part of the subnet 10.3.0.0(<OKD_LAN_24>.0)/255.255.255.0, hence NIC ens4 (<I_OKD_LAN>).

Create firewall rules...

```
firewall-cmd --zone public --add-service=dhcp --permanent
firewall-cmd --reload
```

Enable the service "dhcpd" (DHCP) to automatically start at server boot, start it and watch its log in sequence...

```
systemctl enable dhcpd.service
systemctl restart dhcpd.service
journalctl -u dhcpd.service --no-pager | less +F
```

[Ref(s).: https://bytefreaks.net/gnulinux/centos-7-setup-a-dhcp-server-and-provide-specific-ip-based-on-mac-address ,
https://www.unixmen.com/how-to-install-dhcp-server-in-centos-and-ubuntu/ ,
https://www.appservgrid.com/paw92/index.php/2019/03/14/how-to-setup-dhcp-server-and-client-on-centos-and-ubuntu/ ,
https://tecadmin.net/configuring-dhcp-server-on-centos-redhat/ ,
https://elearning.wsldp.com/pcmagazine/install-centos-7-dhcp-server/ ,
https://elearningsurasakblog.wordpress.com/2019/09/24/how-to-install-and-configure-dhcp-server-on-centos7/ ,
https://linuxhint.com/dhcp_server_centos8/ ,
https://www.tecmint.com/install-dhcp-server-in-centos-rhel-fedora/ ,
https://ask.fedoraproject.org/t/dhcp-does-not-recognise-mac-address-of-interface/1290/36 ]

## Setup the DNS service (ISC BIND 9) (OKD_SERVICES)

Install the packages...

```
dnf -y install bind
dnf -y install bind-utils
```

Copy the config files...

```
cd "/usr/local/src/okd_bare_metal"
mv /etc/named.conf /etc/named.conf_BAK
cp ./named.conf /etc/
cp ./named.conf.local /etc/named/
mkdir "/etc/named/zones"
cp ./rv.okd_domain /etc/named/zones/
cp ./fw.okd_domain /etc/named/zones/
```

Create the firewall rules...

```
firewall-cmd --zone public --add-port=53/udp --permanent
firewall-cmd --reload
```

Modify in the appropriate DHCP the OKD_SERVICES's network settings for the NIC ens3 (<I_INT_LAN>) changing the DNS IP to "127.0.0.1" (LOCALHOST). If you don't use DHCP then you will have to configure these settings locally (manually). See "Network layout..." for more details.

Update the OKD_SERVICES's DHCP client settings...

MODEL

```
dhclient <I_INT_LAN>
```

EXAMPLE

```
dhclient ens3
```

[Ref(s).: https://computingforgeeks.com/install-and-configure-dhcp-server-on-centos-rhel-linux/ ]

Enable the service "named" (BIND 9) to automatically start at server boot, start it and watch its log in sequence...

```
systemctl enable named.service
systemctl restart named.service
journalctl -u named.service --no-pager | less +F
```

Test DNS on the OKD_SERVICES...

MODEL

```
dig <YOUR_DOMAIN>
dig -x <OKD_LAN_24>.<OKD_SERVICES_LST_OCT>
```

EXAMPLE

```
dig domain.abc
dig -x 10.3.0.3
```

Test internet access...

```
curl http://www.google.com
```

## Setup the load balancer service (HAProxy) (OKD_SERVICES)

Install the package...

```
dnf -y install haproxy
```

Copy the config files...

```
cd "/usr/local/src/okd_bare_metal"
mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg_BAK
cp ./haproxy.cfg /etc/haproxy/
```

Allow HAProxy to connect to unbind IP Addresses...

```
tee "/etc/sysctl.d/ip_nonlocal_bind.conf" << EOF
net.ipv4.ip_nonlocal_bind=1
EOF
sysctl -w net.ipv4.ip_nonlocal_bind=1
```

[Ref(s).: https://rahmatawe.com/blog/deploying-upi-okd/ ]

If SELinux is in enforcing mode, allow HAProxy to proxy any port...

```
setsebool -P haproxy_connect_any 1
```

Create firewall rules...

```
firewall-cmd --zone public --add-port=6443/tcp --permanent
firewall-cmd --zone public --add-port=22623/tcp --permanent
firewall-cmd --zone public --add-port=80/tcp --permanent
firewall-cmd --zone public --add-port=443/tcp --permanent
firewall-cmd --reload
```

Enable the service "haproxy" (HAProxy) to automatically start at server boot, start it and watch its log in sequence...

```
systemctl enable haproxy.service
systemctl restart haproxy.service
journalctl -u haproxy.service --no-pager | less +F
```

[Ref(s).: https://github.com/pshchelo/stackdev/blob/master/dib_elements/aws-loadbalancer/install.d/11-haproxy ]

## Setup the NTP service (Chrony) (OKD_SERVICES)

Install the package...

```
dnf install -y chrony
```

Set the timezone...

MODEL

```
timedatectl set-timezone <TIMEZONE>
```

EXAMPLE

```
timedatectl set-timezone America/Sao_Paulo
```

**TIP:** To list the available timezones use the command...

```
timedatectl list-timezones
```
.

Create the firewall rules...

```
firewall-cmd --zone public --add-service=ntp --permanent
firewall-cmd --reload
```

Modify the "/etc/chrony.conf" configuration file to allow NTP clients access from local network...

MODEL

```
sed -i 's/#allow 192.168.0.0\/16/#allow 192.168.0.0\/16\nallow <OKD_LAN_24>.0\/24/g' /etc/chrony.conf
```

EXAMPLE

```
sed -i 's/#allow 192.168.0.0\/16/#allow 192.168.0.0\/16\nallow 10.3.0.0\/24/g' /etc/chrony.conf
```

... and to enable the Chrony server (NTP) to continue to act as if it were connected to the remote reference servers even if the connection (internet, basically) to them fails...

```
sed -i 's/#local stratum 10/local stratum 10/g' /etc/chrony.conf
```

... this, also, enables the host to continue to be an NTP server to other hosts on the local network.

Enable the service "chronyd" (Chrony) to automatically start at server boot, start it and watch its log in sequence...

```
systemctl enable chronyd.service
systemctl restart chronyd.service
journalctl -u chronyd.service --no-pager | less +F
```

Check if the NTP servers are accessible...

```
chronyc sources -v
```

**TIP:** At least 2 or 3 servers must be available. If none are available, there may be some network blocking for the NTP (123/UDP) protocol.

Force clock resynchronization...

```
chronyc -a "burst 3/5"
chronyc makestep 1 -1
```

... and then observe if the "Leap status" has the "status" as "Normal"...

```
chronyc tracking
```
.

[Ref.: https://www.server-world.info/en/note?os=CentOS_7&p=ntp&f=3 ,
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/ch-configuring_ntp_using_the_chrony_suite ]

## Setup the web server (Apache/httpd) (OKD_SERVICES)

A web service will be created to host the resources needed to create the cluster.

Install the package...

```
dnf -y install httpd
```

Change Apache ("httpd") to listen on port 8080...

```
sed -i 's/Listen 80/# Listen 80\nListen 8080/g' /etc/httpd/conf/httpd.conf
```

To avoid the error "[...]httpd: Could not reliably determine the server's fully qualified domain name[...]"...

```
sed -i 's/#ServerName www.example.com:80/#ServerName www.example.com:80\nServerName 127.0.0.1:8080/g' /etc/httpd/conf/httpd.conf
```

[Ref(s).: https://stackoverflow.com/a/46240707/3223785 ]

If SELinux is in enforcing mode, allow Apache ("httpd") to read user content...

```
setsebool -P httpd_read_user_content 1
```

[Ref(s).: https://linux.die.net/man/8/apache_selinux ]

Create firewall rules...

```
firewall-cmd --zone public --add-port=8080/tcp --permanent
firewall-cmd --reload
```

Enable the service "httpd" (Apache) to automatically start at server boot, start it and watch its log in sequence...

```
systemctl enable httpd.service
systemctl restart httpd.service
journalctl -u httpd.service --no-pager | less +F
```

Test the web server...

```
curl http://127.0.0.1:8080
```

## Setup the OpenShift (OKD) (installer and client) (OKD_SERVICES)

### Install the "libvirt" dependency

```
dnf -y install libvirt
```

[Ref(s).: https://github.com/openshift/okd/issues/535#issuecomment-823265674 ,
https://www.gitmemory.com/cgruver ,
https://github.com/openshift/okd/pull/633#pullrequestreview-655775878 ]

### Download the OpenShift (OKD) installer and the "oc" client

Find here https://github.com/openshift/okd/releases the latest version ("Latest release") of openshift-client and openshift-install.

```
dnf -y install wget
cd "/usr/local/src/"
wget https://github.com/openshift/okd/releases/download/4.7.0-0.okd-2021-08-07-063045/openshift-client-linux-4.7.0-0.okd-2021-08-07-063045.tar.gz
wget https://github.com/openshift/okd/releases/download/4.7.0-0.okd-2021-08-07-063045/openshift-install-linux-4.7.0-0.okd-2021-08-07-063045.tar.gz
```

**NOTE:** The latest version ("Latest release") in the creation of this tutorial was "4.7.0-0.okd-2021-08-07-063045".

Extract the OpenShift (OKD) installer and the "oc" client...

```
dnf -y install tar
cd "/usr/local/src/"
tar -zxvf openshift-client-linux-4.7.0-0.okd-2021-08-07-063045.tar.gz
tar -zxvf openshift-install-linux-4.7.0-0.okd-2021-08-07-063045.tar.gz
```

Move the "kubectl", "oc" and "openshift-install" to "/usr/local/bin" folder...

```
cd "/usr/local/src/"
mv ./kubectl /usr/local/bin/
mv ./oc /usr/local/bin/
mv ./openshift-install /usr/local/bin/
rm -f README.md
```

### Test the OpenShift (OKD) installer and client

Test showing the versions of "oc" and "openshift-install"...

```
oc version
openshift-install version
```

### Setup the OpenShift (OKD) installer

Generate a SSH key...

MODEL

```
ssh-keygen -t rsa -C "okd-services.<YOUR_DOMAIN>"
```

EXAMPLE

```
ssh-keygen -t rsa -C "okd-services.domain.abc"
```

... using the default options. So, use empty "passphrase".

Then add the SSH private keys into the SSH authentication agent to implementing single sign-on with SSH...

```
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
```

[Ref(s).: https://www.ssh.com/academy/ssh/add ,
https://docs.gitlab.com/ee/ssh/ ,
https://git-scm.com/book/pt-pt/v2/Git-no-Servidor-Generating-Your-SSH-Public-Key ,
https://docs.okd.io/latest/installing/installing_gcp/installing-gcp-customizations.html#ssh-agent-using_installing-gcp-customizations ]

Set the "sshKey" parameter in the "install-config.yaml" file with your public key ("id_rsa.pub") value generated in the previous step ...

```
TARGET_ARG="<SSH_PUB_KEY>"
REPLACE_ARG=$(cat ~/.ssh/id_rsa.pub)
FILE_ARG="/usr/local/src/okd_bare_metal/install-config.yaml"
REPLACE_ARG=$(echo "'${REPLACE_ARG}'" | sed 's/[]\/$*.^|[]/\\&/g' | sed 's/\t/\\t/g' | sed ':a;N;$!ba;s/\n/\\n/g')
REPLACE_ARG=${REPLACE_ARG%?}
REPLACE_ARG=${REPLACE_ARG#?}
SED_ARGS="'s/$TARGET_ARG/$REPLACE_ARG/g'"
eval "sed -i $SED_ARGS $FILE_ARG"
```

**NOTE:** The above commands automatically sets the "sshKey" parameter value escaping arguments to the "sed" command that actually does the job.

[Ref(s).: https://rahmatawe.com/blog/deploying-upi-okd/ ]

### Setup the cluster's install directory

Create an cluster's install directory and copy the "install-config.yaml" file...

```
mkdir "/usr/local/okd"
cp /usr/local/src/okd_bare_metal/install-config.yaml /usr/local/okd/
```

**TIP:** If you need to reuse the "/usr/local/okd/" folder, make sure it is empty. Hidden files are created after generating the configs and they should be removed before you use the same folder on a new attempt.

### Generate the Kubernetes manifests

Generate the Kubernetes manifests for the cluster...

```
openshift-install create manifests --dir=/usr/local/okd/
```

**NOTE:** Ignore the warning.

Modify the "cluster-scheduler-02-config.yml" manifest file to prevent pods from being scheduled ("mastersSchedulable") on the master nodes...

```
sed -i 's/mastersSchedulable: true/mastersSchedulable: false/g' /usr/local/okd/manifests/cluster-scheduler-02-config.yml
```

**NOTE:** The above procedure is required for an installation over an User-Provisioned Infrastructure (UPI)/"bare-metal".

### Create the ignition configuration files

Create the "ignition-configs"...

```
openshift-install create ignition-configs --dir=/usr/local/okd/
```

### Add the ignition and the Fedora CoreOS/FCOS files to the web server

Create the web service's "okd" folder in the "/var/www/html" path...

```
mkdir "/var/www/html/okd"
```

Copy the "/usr/local/okd/" folder contents to the "/var/www/html/okd" folder...

```
cp -r /usr/local/okd/* /var/www/html/okd/
```

Download the Fedora CoreOS/FCOS Stable (Bare Metal) bios image (look for "Raw"/"raw.xz") and the sig files (look for "raw.xz.sig"), shorten the file names and set the necessary permissions...

**NOTE:** These resources can be found here https://getfedora.org/coreos/download?tab=cloud_launchable&stream=stable in the "Bare Metal & Virtualized" tab.

```
cd "/var/www/html/okd"
wget https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/34.20210725.3.0/x86_64/fedora-coreos-34.20210725.3.0-metal.x86_64.raw.xz
wget https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/34.20210725.3.0/x86_64/fedora-coreos-34.20210725.3.0-metal.x86_64.raw.xz.sig
mv ./fedora-coreos-34.20210725.3.0-metal.x86_64.raw.xz ./fcos.raw.xz
mv ./fedora-coreos-34.20210725.3.0-metal.x86_64.raw.xz.sig ./fcos.raw.xz.sig
chown -R apache: /var/www/html/
chmod -R 755 /var/www/html/
```

**NOTE:** The stable version at creation of this tutorial was "34.20210725.3.0".

Restart the Apache ("httpd") service...

```
systemctl restart httpd.service
```

# Create the OKD_BOOTSTRAP, OKD_MASTER_Xs and OKD_WORKER_Xs nodes

## Create the virtual machines (OKD_BOOTSTRAP, OKD_MASTER_Xs and OKD_WORKER_Xs) (HYPERVISOR)

Download a Fedora CoreOS/FCOS Stable (Bare Metal) ISO...

These resources can be found here https://getfedora.org/coreos/download?tab=cloud_launchable&stream=stable in the "Bare Metal & Virtualized" tab.

```
wget https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/34.20210725.3.0/x86_64/fedora-coreos-34.20210725.3.0-live.x86_64.iso
```

**IMPORTANT:** The stable version at creation of this tutorial was "34.20210725.3.0". Use the SAME VERSION used when the bios image and sig files were downloaded.

Enable Nested Virtualization. For more details see the section "KVM Nested Virtualization - Virtualization Support or Hardware-Assisted Virtualization for guests".

They must have access to N_OKD_LAN ("okd_network") network. See "Network layout..." for more details.

In this step we will not install any operating system we will just provision the hardware resources on the hypervisor (host) without install anything.

## Create the bootstrap node (OKD_BOOTSTRAP)

### Starting the virtual machine (guest)

Configure OKD_BOOTSTRAP to use ISO "fedora-coreos-34.20210725.3.0-live.x86_64.iso" on boot.

### Configure parameters on boot

Once the virtual machine starts press the "TAB" key during boot to edit the kernel boot options and add the following...

MODEL

```
coreos.inst.install_dev=<DISK_DEVICE_PATH> coreos.inst.image_url=http://<OKD_LAN_24>.<OKD_SERVICES_LST_OCT>:8080/okd/fcos.raw.xz coreos.inst.ignition_url=http://<OKD_LAN_24>.<OKD_SERVICES_LST_OCT>:8080/okd/bootstrap.ign
```

EXAMPLE

```
coreos.inst.install_dev=/dev/vda coreos.inst.image_url=http://10.3.0.3:8080/okd/fcos.raw.xz coreos.inst.ignition_url=http://10.3.0.3:8080/okd/bootstrap.ign
```

... right after the existing settings that is something like this...

```
/images/pxeboot/vmlinuz initrd=/images/pxeboot/initrd.img,/images/ignition.img systemd.unified_cgroup_hierarchy=0 mitigations=auto,nosmt coreos.liveiso=fedora-coreos-34.20210725.3.0 ignition.firstboot ignition.platform.id=metal
```

... so the final appearance will be something like this...

```
/images/pxeboot/vmlinuz initrd=/images/pxeboot/initrd.img,/images/ignition.img systemd.unified_cgroup_hierarchy=0 mitigations=auto,nosmt coreos.liveiso=fedora-coreos-34.20210725.3.0 ignition.firstboot ignition.platform.id=metal coreos.inst.install_dev=/dev/sda coreos.inst.image_url=http://10.3.0.3:8080/okd/fcos.raw.xz coreos.inst.ignition_url=http://10.3.0.3:8080/okd/bootstrap.ign
```

**Tag values...**
 * <DISK_DEVICE_PATH> - Path to disk device. E.g.: "/dev/sda", "/dev/vda";
 * <OKD_SERVICES_LST_OCT> - Last octet of machine IP OKD_SERVICES. E.g.: "3";
 * <OKD_LAN_24> - First three octets of N_OKD_LAN. E.g.: "10.3.0".

Added the necessary parameters and press "ENTER", then the process will start downloading the resources from the services server (OKD_SERVICES) (the image "fcos.raw.gz" and its signature).

**TIP:** To insert the above entry using the "virt-manager" do as follows. From "View" > "Console" (virtal machine/guest management), go (again) to "View" > "Consoles" > "Serial 1". This mode will allow you to select the "Paste" option with the second mouse button.

After the end of the process above, the system will reboot and after the reboot configure the OKD_BOOTSTRAP to use its hard disk at boot, that is, disable ISO as boot option.

If everything goes well, the system will boot and the start screen will appear asking for login. It will look like this...

```
Fedora CoreOS 34.20210725.3.0
Kernel 5.13.4-200.fc34.x86_64 on an x86_64 (ttyl)

okd-bootstrap login:
```

**NOTE:** The OS will print/output a number of other information on screen that will get mixed up with the traditional components of the login screen described above. As far as we know this is "normal".

**IMPORTANT:** At this point, you might want, right now, to take a look at the guidelines in the "Follow the bootstrap process evolution (OKD_SERVICES)" (Especially in the "Some relevant guidelines" section). You might be able to avoid a lot of problems with the guidelines that are there.

## Create the masters nodes (OKD_MASTER_1, OKD_MASTER_2 and OKD_MASTER_3)

Follow the same instructions as in "Starting the bootstrap node (OKD_BOOTSTRAP)" with the exception of what is in the section "Configure parameters on boot" that must be done according to these specific settings...

MODEL

```
coreos.inst.install_dev=<DISK_DEVICE_PATH> coreos.inst.image_url=http://<OKD_LAN_24>.<OKD_SERVICES_LST_OCT>:8080/okd/fcos.raw.xz coreos.inst.ignition_url=http://<OKD_LAN_24>.<OKD_SERVICES_LST_OCT>:8080/okd/master.ign
```

EXAMPLE

```
coreos.inst.install_dev=/dev/vda coreos.inst.image_url=http://10.3.0.3:8080/okd/fcos.raw.xz coreos.inst.ignition_url=http://10.3.0.3:8080/okd/master.ign
```

**IMPORTANT:** It is normal that at the beginning a master node continuously display an error like to the following...

```
[   83.933709] ignition[531]: GET https://api-int.mbr.domain.abc:22623/config/master: attempt #16
[   83.939340] ignition[531]: GET error: Get "https://api-int.mbr.domain.abc:22623/config/master": EOF
```

... , however with the bootstrap node (OKD_BOOTSTRAP) running (after passing the ignition phase) the above situation MUST NOT EXTEND FOR MORE THAN 10 MINUTES. If you exceed this amount of time, something has certainly gone wrong.

**IMPORTANT:** Although it is not mandatory to wait for the bootstrap process to occur only with the master nodes running. As a matter of practicality it is better to do the process this way since for the bootstrap process to occur only they are needed.

## Create the workers nodes (OKD_WORKER_1 and OKD_WORKER_2)

Follow the same instructions as in "Starting the bootstrap node (OKD_BOOTSTRAP)" with the exception of what is in the section "Configure parameters on boot" that must be done according to these specific settings...

MODEL

```
coreos.inst.install_dev=<DISK_DEVICE_PATH> coreos.inst.image_url=http://<OKD_LAN_24>.<OKD_SERVICES_LST_OCT>:8080/okd/fcos.raw.xz coreos.inst.ignition_url=http://<OKD_LAN_24>.<OKD_SERVICES_LST_OCT>:8080/okd/worker.ign
```

EXAMPLE

```
coreos.inst.install_dev=/dev/vda coreos.inst.image_url=http://10.3.0.3:8080/okd/fcos.raw.xz coreos.inst.ignition_url=http://10.3.0.3:8080/okd/worker.ign
```

**IMPORTANT:** It is normal that at the beginning a worker node continuously display an error like to the following...

```
[  139.524957] ignition[532]: GET https://api-int.mbr.domain.abc:22623/config/worker: attempt #31
[  139.528886] ignition[532]: GET result: Internal Server Error
```

... , however with all nodes running (after passing the ignition phase) the above situation MUST NOT EXTEND FOR MORE THAN 30 MINUTES. If you exceed this amount of time, something has certainly gone wrong.

## Follow the bootstrap process evolution (OKD_SERVICES)

To follow the evolution of the bootstrap process in the OKD_SERVICES use the command...

```
openshift-install wait-for bootstrap-complete --log-level=info --dir=/usr/local/okd/
```

... and to follow with more details on bootstrap node (OKD_BOOTSTRAP), access via ssh (no password required)...

MODEL

```
ssh core@<OKD_LAN_24>.<OKD_BOOTSTRAP_LST_OCT>
```

EXAMPLE

```
ssh core@10.3.0.19
```

... and run this command...

```
journalctl -b -f -u release-image.service -u bootkube.service
```
.

**IMPORTANT:** The bootstrap process only ends when "all" the nodes - in fact only the master nodes need to be - have been created and an output like to the one below is observed for the `openshift-install wait-for bootstrap-complete --log-level=info --dir=/usr/local/okd/` command...

```
[...]
INFO Waiting up to 20m0s for the Kubernetes API at https://api.mbr.domain.abc:6443...
INFO API v1.20.0-1077+2817867655bb7b-dirty up
INFO Waiting up to 30m0s for bootstrapping to complete...
INFO It is now safe to remove the bootstrap resources
INFO Time elapsed: 1350s
```

... and an output like to the one below is observed for the `openshift-install wait-for bootstrap-complete --log-level=info --dir=/usr/local/okd/` command...

```
[...]
Jul 19 01:57:25 okd-bootstrap bootkube.sh[15619]: I0719 01:57:25.084944       1 waitforceo.go:67] waiting on condition EtcdRunningInCluster in etcd CR /cluster to be True.
Jul 19 01:57:26 okd-bootstrap bootkube.sh[15619]: I0719 01:57:26.369145       1 waitforceo.go:67] waiting on condition EtcdRunningInCluster in etcd CR /cluster to be True.
Jul 19 01:57:32 okd-bootstrap bootkube.sh[15619]: I0719 01:57:32.655288       1 waitforceo.go:64] Cluster etcd operator bootstrapped successfully
Jul 19 01:57:32 okd-bootstrap bootkube.sh[15619]: I0719 01:57:32.657829       1 waitforceo.go:58] cluster-etcd-operator bootstrap etcd
Jul 19 01:57:32 okd-bootstrap podman[15619]: 2021-07-19 01:57:32.878374998 +0000 UTC m=+1110.936765616 container died 4c828c19c702ee51fc6eda68d52859ca2c477eb90aca9266273ff778aa1048ed (image=quay.io/openshift/okd-content@sha256:7707231ca5ce9c574cbcc8cd10b5b311fb98d59907f01696a76ea75e5ee65f09, name=reverent_morse)
Jul 19 01:57:33 okd-bootstrap bootkube.sh[9228]: bootkube.service complete
Jul 19 01:57:33 okd-bootstrap systemd[1]: bootkube.service: Deactivated successfully.
Jul 19 01:57:33 okd-bootstrap systemd[1]: bootkube.service: Consumed 17.878s CPU time.
```
.

**NOTE:** The node workers are created from the master nodes.

### Some relevant guidelines

 1. It is "normal" to see a lot of errors in the output of the `journalctl -b -f -u release-image.service -u bootkube.service` command. Note, however, that some actions fail at first but end up succeeding later;
 2. Although it is not necessary to wait for this event to start the master nodes (OKD_MASTER_X), the OKD_BOOTSTRAP node will be ready for the master nodes when the log (command above) reach outputs similar to these...

```
[...]
Jul 18 23:12:02 okd-bootstrap bootkube.sh[5146]: Created "99-okd-worker-disable-mitigations.yaml" machineconfigs.v1.machineconfiguration.openshift.io/99-okd-worker-disable-mitigations -n
Jul 18 23:12:02 okd-bootstrap bootkube.sh[5146]: Created "99_openshift-cluster-api_master-user-data-secret.yaml" secrets.v1./master-user-data -n openshift-machine-api
Jul 18 23:12:03 okd-bootstrap bootkube.sh[5146]: Created "99_openshift-cluster-api_worker-user-data-secret.yaml" secrets.v1./worker-user-data -n openshift-machine-api
Jul 18 23:12:03 okd-bootstrap bootkube.sh[5146]: Created "99_openshift-machineconfig_99-master-ssh.yaml" machineconfigs.v1.machineconfiguration.openshift.io/99-master-ssh -n
Jul 18 23:12:03 okd-bootstrap bootkube.sh[5146]: Created "99_openshift-machineconfig_99-worker-ssh.yaml" machineconfigs.v1.machineconfiguration.openshift.io/99-worker-ssh -n
user-data-secret
```

... which will happen after the bootstrap node (OKD_BOOTSTRAP) reboot. New entries will stop appearing in the log until you add the master nodes;

 3. The same reasoning above applies to the node workers when the log (command above) reach outputs similar to the ones below and stop printing for some minutes...

```
[...]
-version/cluster-version-operator        Ready
Jul 18 23:58:37 okd-bootstrap bootkube.sh[17729]:         Pod Status:openshift-kube-apiserver/kube-apiserver        RunningNotReady
Jul 18 23:58:37 okd-bootstrap bootkube.sh[17729]:         Pod Status:openshift-kube-scheduler/openshift-kube-scheduler        RunningNotReady
Jul 18 23:58:37 okd-bootstrap bootkube.sh[17729]:         Pod Status:openshift-kube-controller-manager/kube-controller-manager        Ready
Jul 18 23:58:37 okd-bootstrap bootkube.sh[17729]:         Pod Status:openshift-cluster-version/cluster-version-operator        Ready
Jul 18 23:59:07 okd-bootstrap bootkube.sh[17729]:         Pod Status:openshift-kube-controller-manager/kube-controller-manager        Ready
Jul 18 23:59:07 okd-bootstrap bootkube.sh[17729]:         Pod Status:openshift-cluster-version/cluster-version-operator        Ready
Jul 18 23:59:07 okd-bootstrap bootkube.sh[17729]:         Pod Status:openshift-kube-apiserver/kube-apiserver        RunningNotReady
Jul 18 23:59:07 okd-bootstrap bootkube.sh[17729]:         Pod Status:openshift-kube-scheduler/openshift-kube-scheduler        Ready
```

... all master nodes are expected to reboot twice, so that everything is ready to create the worker nodes;

 4. The nodes must remain ALL THE TIME with the names they got from DHCP service (transient name). This is a sign that everything is going well. If a node shows "localhost" as its name, the process has failed. There may be a problem with the DHCP service (OKD_SERVICES) settings;
 5. It is also expected that all worker nodes will be rebooted twice, so that everything is effectively finished;

--------

**TIPS:**
 1. If your bootstrap process is failing repeatedly, you may need to increase the nodes' RAM beyond the minimum requirements - at the moment we don't recommend do it. However, keep in mind that if the process repeatedly fails effectively something bad is happening even to the consumed remote resources. We've had cases where the bootstrap process repeatedly failed with a certain configuration and two days later it worked perfectly with it. If these remote resources are in trouble, your cluster is at risk of being compromised forever;
 2. You can wait for the bootstrap process to be completed with only the master nodes as only they are needed for it and then add the worker nodes. Although it is not mandatory to wait for the bootstrap process to occur only with the master nodes running. As a matter of practicality it is better to do the process this way since for the bootstrap process to occur only they are needed;
 3. If a new attempt is needed (bootstrap the cluster again) remove the folders `rm -rf /usr/local/okd/` and `rm -rf /var/www/html/okd` in the OKD_SERVICES server, recreate all nodes - clean/recreate its hard disks - and restart the process from the subsection "Setup the cluster's install directory" of the section "Setup the OpenShift (OKD) (installer and client) (OKD_SERVICES)".

--------

--------

**TIP:** You can connect to any node with "ssh" from the machine where you generate the ssh certificate (OKD_SERVICES)...

MODEL

```
ssh core@<OKD_LAN_24>.<OKD_NODENAME_LST_OCT>
```

EXAMPLE

```
ssh core@10.3.0.19
```

... and to login as "root" use `sudo su` command.

--------

## Remove the bootstrap node (OKD_SERVICES) (HYPERVISOR)

Once the bootstrap process is finished, then the "httpd" (Apache) service (OKD_SERVICES) and the bootstrap node (OKD_BOOTSTRAP) will no longer be needed.

### Disable "httpd" (Apache) service (OKD_SERVICES)

Remove firewall rules...

```
firewall-cmd --zone public --remove-port=8080/tcp
firewall-cmd --runtime-to-permanent
firewall-cmd --reload
```

Stop the "httpd" (Apache) service and disable it to automatic start at server boot...

```
systemctl stop httpd.service
systemctl disable httpd.service
```

### Remove the bootstrap node 

Comment out the bootstrap node and restart the HAProxy (load balancer) service (OKD_SERVICES)...

```
sed -i 's/server okd-bootstrap/# server okd-bootstrap/g' /etc/haproxy/haproxy.cfg
systemctl restart haproxy.service
```

Remove the bootstrap machine itself from the hypervisor (host) (HYPERVISOR).

[Ref(s).: https://docs.okd.io/latest/installing/installing_bare_metal/installing-bare-metal.html ]

# Finalize setup on the OKD_SERVICES server

## Login to the cluster and approve all CSRs (OKD_SERVICES)

Now that the master nodes are online, you should be able to login with the "oc" client. Use the following commands to log in and check some information about your cluster...

```
export KUBECONFIG=/usr/local/okd/auth/kubeconfig
oc whoami
oc get nodes
oc get csr
```

**NOTE:** With the `oc whoami` command you should see the default administrator username, with the `oc get nodes` command you should see only the master nodes and with the `oc get csr` command you should see several CSRs (including worker nodes) awaiting approval.

--------

**TIP:** You can add ("export") the environment variable "KUBECONFIG" globally and permanently using the file "/etc/environment". This way you won't need to export this variable every time you log in...

```
tee "/etc/environment" << EOF
KUBECONFIG=/usr/local/okd/auth/kubeconfig
EOF
```

[Ref(s).: https://stackoverflow.com/a/31546962/3223785 ,
https://unix.stackexchange.com/a/117473/61742 ]

--------

### Install the "jq" package

Install the "jq" package to assist you with some maintenance operations...

```
cd "/usr/local/src"
wget -O jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
mv ./jq /usr/local/bin/
chmod +x /usr/local/bin/jq

# To test/show version.
jq --version
```

**NOTE:** The latest release version at the time this tutorial was created was 1.6.

## Join Worker Nodes...

### Approve all pending CSRs

Approve all pending CSRs...

```
oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve
```

--------

**IMPORTANT:**

Once you approve the first set of CSRs additional CSRs will be created. These must be approved too. If you do not see pending requests wait a moment.

Watch and wait for the worker nodes to join the cluster and enter a "Ready" status. This can take 5~10 minutes...

```
watch -n5 oc get nodes
```

--------

--------

**TIP:** Alternatively you can use "jq" in the same way and approve all the pending CSRs...

```
oc get csr -ojson | jq -r '.items[] | select(.status == {} ) | .metadata.name' | xargs oc
```

--------

## Setup the NFS service (NFS Utilities) (OKD_SERVICES)

Let's configure our OKD_SERVICES as an NFS (Network File Sharing) server and use it for persistent storage.

Install the package...

```
dnf install -y nfs-utils
```

Create a NFS share registry directory...

```
mkdir -p /var/nfsshare/registry
```

Create an NFS export...

Add the entry below to the "/etc/exports" file...

MODEL

```
echo "/var/nfsshare <OKD_LAN_24>.0/24(rw,sync,no_root_squash,no_all_squash,no_wdelay)" | tee /etc/exports
```

EXAMPLE

```
echo "/var/nfsshare 10.3.0.0/24(rw,sync,no_root_squash,no_all_squash,no_wdelay)" | tee /etc/exports
```

Set the necessary permissions...

```
chmod -R 777 /var/nfsshare
chown -R nobody:nobody /var/nfsshare
```

If SELinux is in enforcing mode, allow NFS ("nfs-server") to export all...

```
setsebool -P nfs_export_all_rw 1
```

Create firewall rules...

```
firewall-cmd --zone public --add-service mountd --permanent
firewall-cmd --zone public --add-service rpc-bind --permanent
firewall-cmd --zone public --add-service nfs --permanent
firewall-cmd --reload
```

Enable the services "nfs-server"/"rpcbind" (NFS) to automatically start at server boot, start them and watch its logs in sequence...

```
systemctl enable nfs-server.service
systemctl restart nfs-server.service
journalctl -u nfs-server.service --no-pager | less +F
```

```
systemctl enable rpcbind.service
systemctl restart rpcbind.service
journalctl -u rpcbind.service --no-pager | less +F
```

### Registry configuration

Verify the image registry operator ("cluster-image-registry-operator-*") is running in the openshift-image-registry namespace...

```
oc get pod -n openshift-image-registry | grep "cluster-image-registry-operator-*"
```

Change "managementState" (Image Registry Operator) configuration from "Removed" to "Managed"...

```
oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState": "Managed"}}'
```

Use the following command to create the PV using the YAML file...

```
oc create -f /usr/local/src/okd_bare_metal/registry_pv.yaml
```

Verify the status of the newly created PV...

```
oc get pv
```

... and check if the "STATUS" attribute is "Available" for "registry-pv" ("NAME").

Use the following command to create the PVC using the YAML file...

```
oc create -n openshift-image-registry -f /usr/local/src/okd_bare_metal/registry_pvc.yaml
```

Verify the status of the newly created PVC...

```
oc get pvc -n openshift-image-registry
```

... and check if the "STATUS" attribute is "Bound" for "registry-pvc" ("NAME").

Add the PVC to the cluster...

```
oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"storage":{"managementState":"Managed","pvc":{"claim":"registry-pvc"}}}}'
```

Verify, again, the status of PV...

```
oc get pv
```

... and check if the "STATUS" attribute is "Bound" for "registry-pv" ("NAME").

[Ref(s).: https://www.cisco.com/c/en/us/td/docs/unified_computing/ucs/UCS_CVDs/flexpod_openshift_platform_4.html ,
https://www.walkersblog.net/documents/openshift/openshift.html ]

## Configure nodes as NTP (chrony) clients (OKD_MASTER_Xs and OKD_WORKER_Xs) (OKD_SERVICES)

Configure the cluster nodes as NTP (chrony) clients.

### Create the NTP (chrony) client configuration file

Open a SSH connection to a master node (OKD_MASTER_X)...

MODEL

```
ssh core@<OKD_LAN_24>.<OKD_MASTER_X_LST_OCT>
```

EXAMPLE

```
ssh core@10.3.0.4
```

... and switch to root...

```
sudo su
```

Create a "chrony.conf" from an existing one...

```
cd "/usr/local/src"
grep -v -e '^#' -e '^$' /etc/chrony.conf > chrony.conf
```

Copy the contents of the generated "chrony.conf" configuration file...

```
cd "/usr/local/src"; cat chrony.conf
```

... and remove it...

```
cd "/usr/local/src"
rm -f chrony.conf
```

Close the master node's SSH connection (OKD_MASTER_X).

Create a "chrony.conf" file at the service server (OKD_SERVICES) using the content obtained above and make the necessary adjustments as below...

MODEL

```
read -r -d '' FILE_CONTENT << 'HEREDOC'
BEGIN
pool 2.fedora.pool.ntp.org iburst
sourcedir /run/chrony-dhcp
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
keyfile /etc/chrony.keys
ntsdumpdir /var/lib/chrony
leapsectz right/UTC
logdir /var/log/chrony
server <OKD_LAN_24>.<OKD_SERVICES_LST_OCT> iburst prefer

END
HEREDOC
echo -n "${FILE_CONTENT:6:-3}" > '/usr/local/src/chrony.conf'
```

EXAMPLE

```
read -r -d '' FILE_CONTENT << 'HEREDOC'
BEGIN
pool 2.fedora.pool.ntp.org iburst
sourcedir /run/chrony-dhcp
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
keyfile /etc/chrony.keys
ntsdumpdir /var/lib/chrony
leapsectz right/UTC
logdir /var/log/chrony
server 10.3.0.3 iburst prefer

END
HEREDOC
echo -n "${FILE_CONTENT:6:-3}" > '/usr/local/src/chrony.conf'
```

**NOTE:** The above configuration makes a NTP (chrony) client to consume the service server (OKD_SERVICES) as the preferred reference source.

### Configure chrony on master and worker nodes (OKD_SERVICES)

Encode the "chrony.conf" file...

```
cd "/usr/local/src"
base64 chrony.conf > chrony.conf.encoded
```

Set the "source" parameter in the "chrony_conf_master.yaml" and "chrony_conf_worker.yaml" files ("okd_bare_metal" folder) with the contents of the "chrony.conf.encoded" file generated in the previous step...

```
TARGET_ARG="<SOURCE_CHRONY_CONF>"
REPLACE_ARG=$(cat /usr/local/src/chrony.conf.encoded | awk '{print}' ORS='')
FILE_ARG_MASTER="/usr/local/src/okd_bare_metal/chrony_conf_master.yaml"
FILE_ARG_WORKER="/usr/local/src/okd_bare_metal/chrony_conf_worker.yaml"
REPLACE_ARG=$(echo "'${REPLACE_ARG}'" | sed 's/[]\/$*.^|[]/\\&/g' | sed 's/\t/\\t/g' | sed ':a;N;$!ba;s/\n/\\n/g')
REPLACE_ARG=${REPLACE_ARG%?}
REPLACE_ARG=${REPLACE_ARG#?}
SED_ARGS="'s/$TARGET_ARG/$REPLACE_ARG/g'"
eval "sed -i $SED_ARGS $FILE_ARG_MASTER"
eval "sed -i $SED_ARGS $FILE_ARG_WORKER"
```

**NOTE:** The above commands automatically sets the "source" parameter value escaping arguments to the "sed" command that actually does the job.

Set the new NTP (chrony) client configuration for the worker nodes (OKD_WORKER_Xs)...

```
cd "/usr/local/src/okd_bare_metal"
oc apply -f /usr/local/src/okd_bare_metal/chrony_conf_worker.yaml
```

Set the new NTP (chrony) client configuration for the master nodes (OKD_MASTER_Xs)...

```
cd "/usr/local/src/okd_bare_metal"
oc apply -f /usr/local/src/okd_bare_metal/chrony_conf_master.yaml
```

**NOTE:** Creating the configurations causes each master and worker node to schedule a reboot.

### Configure nodes timezone (OKD_MASTER_Xs and OKD_WORKER_Xs)

This procedure must be performed on each node.

Open a SSH connection...

MODEL

```
ssh core@<OKD_LAN_24>.<OKD_NODE_LST_OCT>
```

EXAMPLE

```
ssh core@10.3.0.4
```

... and switch to root...

```
sudo su
```

Set the timezone...

MODEL

```
timedatectl set-timezone <TIMEZONE>
```

EXAMPLE

```
timedatectl set-timezone America/Sao_Paulo
```

Force clock resynchronization...

```
chronyc -a "burst 3/5"
chronyc makestep 1 -1
```

... and then observe if the "Leap status" has the "status" as "Normal"...

```
chronyc tracking
```
.

IMPORTANT: The cluster nodes take about 10~15 minutes to start consuming the service server (OKD_SERVICES) as source. This can be seen using the command...

`
chronyc sources -v
`
.

[Ref(s).: https://www.walkersblog.net/documents/openshift/openshift.html#_ntpchrony ,
https://docs.openshift.com/container-platform/4.4/installing/install_config/installing-customizing.html#installation-special-config-chrony_installing-customizing ,
https://opensource.com/article/18/12/manage-ntp-chrony ,
https://wiki.crowncloud.net/?How_to_Sync_Time_in_CentOS_8_using_Chrony ,
https://rahmatawe.com/blog/deploying-upi-okd/ ,
https://computingforgeeks.com/configure-chrony-ntp-service-on-openshift-okd/ ]

## HTPasswd Setup (OKD_SERVICES)

### Get your "kubeadmin" password

```
cat /usr/local/okd/auth/kubeadmin-password
```

**NOTE:** The user "kubeadmin" can be used to log in to the Web Console.

### Set a new admin user

The "kubeadmin" is just an initial user. The easiest way to set up a local user is with "htpasswd"...

MODEL

```
cd "/usr/local/src/okd_bare_metal"
htpasswd -c -B -b users.htpasswd <OKD_ADM_USR> <OKD_ADM_PWD>
```

EXAMPLE

```
cd "/usr/local/src/okd_bare_metal"
htpasswd -c -B -b users.htpasswd okdadmusr MySeCREtvalUE
```

Create a secret in the "openshift-config" project using the "users.htpasswd" file you generated...

```
cd "/usr/local/src/okd_bare_metal"
oc create secret generic htpass-secret --from-file=htpasswd=users.htpasswd -n openshift-config
```

Add the identity provider...

```
cd "/usr/local/src/okd_bare_metal"
oc apply -f /usr/local/src/okd_bare_metal/htpasswd_provider.yaml
```

**NOTE:** Ignore the warning.

Give "cluster-admin" access to the new user...

MODEL

```
oc adm policy add-cluster-role-to-user cluster-admin <OKD_ADM_USR>
```

EXAMPLE

```
oc adm policy add-cluster-role-to-user cluster-admin okdadmusr
```

**NOTE:** Now, the created user has cluster administrator level access.

## Test the web console

Test whether the web console is available...

MODEL

```
curl -k https://console-openshift-console.apps.mbr.<YOUR_DOMAIN>
```

EXAMPLE

```
curl -k https://console-openshift-console.apps.mbr.domain.abc
```

--------

**NOTE:** The Web Console may take a few minutes to become available. It is normal for the above command to initially display an error like below...

```
[root@okd-services ~]# curl -k https://console-openshift-console.apps.mbr.domain.abc
curl: (35) OpenSSL SSL_connect: SSL_ERROR_SYSCALL in connection to console-openshift-console.apps.mbr.domain.abc:443
```

... or an error like below...

```
The application is currently not serving requests at this endpoint. It may not have been started or is still starting.
```
.

--------

--------

**TIP:** To check all available routes...

```
oc get routes --all-namespaces
```
.

--------

From your desktop browser, test access to the Web Console using an URL like this example...

```
https://console-openshift-console.apps.mbr.domain.abc
```

... and on the first login screen use the "htpasswd_provider" option and then the username and password created in the "HTPasswd Setup (OKD_SERVICES)" section.

--------

**TIP:** Test Web Console access from your desktop without having to publish the OpenShift (OKD) web resources on an external DNS on the Internet.

Add an entry as this example...

```
127.0.0.1 alertmanager-main-openshift-monitoring.apps.mbr.domain.abc canary-openshift-ingress-canary.apps.mbr.domain.abc console-openshift-console.apps.mbr.domain.abc downloads-openshift-console.apps.mbr.domain.abc grafana-openshift-monitoring.apps.mbr.domain.abc oauth-openshift.apps.mbr.domain.abc prometheus-k8s-openshift-monitoring.apps.mbr.domain.abc thanos-querier-openshift-monitoring.apps.mbr.domain.abc wordpress-wordpress-test.apps.mbr.domain.abc
```

... in your...

```
sudo vi "/etc/hosts"
```

... file, create a ssh tunnel to the remote web service (ports 80/http and 443/https) via the ssh command...

MODEL

```
sudo ssh root@<SSH_INT_IP> -p 573 -CNL :80:<INT_LAN_24>.<OKD_SERVICES_IL_LST_OCT>:80 -CNL :443:<INT_LAN_24>.<OKD_SERVICES_IL_LST_OCT>:443
```

EXAMPLE

```
sudo ssh root@123.456.789.10 -p 573 -CNL :80:10.2.0.18:80 -CNL :443:10.2.0.18:443
```

[Ref(s).: https://stackoverflow.com/a/29937009/3223785 ]

--------

# Access OpenShift (OKD) web resources behind a Ngnix reverse proxy (NGINX_REVERSE_PROXY)

As this is a very common need and setup in network infrastructures we will show how to allow access to OpenShift (OKD) web resources behind a Ngnix reverse proxy using a wildcard setting for your DNS (external) and a Let's Encrypt wildcard SSL certificate.

In a simplified way the updated network layout will look like below.

Network layout updated with Nginx reverse proxy...

```
.---------------------.
|        WAN          |
|         ↕           |
| NGINX_REVERSE_PROXY |
|         ↕           |
|    OKD_SERVICES     |
|         ↕           |
|       [...]         |
'---------------------'
```

The required procedures are in the "Setup Let's Encrypt Wildcard SSL Certificate with Nginx Reverse Proxy" section.

The NGINX_REVERSE_PROXY must have access to N_INT_LAN ("default") network.

# Access OpenShift (OKD) using OpenLDAP (LDAP) as identity provider (OKD_SERVICES)

As this is a very common need and setup, we will show you how to allow access to OpenShift (OKD) resources using OpenLDAP (LDAP) as identity provider.

The required procedures are in the "OpenLDAP (LDAP) e OpenShift (OKD) - Configuring OpenLDAP (LDAP) as identity provider for OpenShift (OKD)" section.

# Test the cluster (OKD_SERVICES)

## Create a WordPress test project

Create a new project...

```
oc new-project wordpress-test
```

Create a new app using a CentOS 7 ("php-73-centos7") S2I ("source-to-image") image from docker hub and use the WordPress GitHub repo as the source...

```
oc new-app centos/php-73-centos7~https://github.com/WordPress/WordPress.git
```

**NOTES:**
1. If an error occurs stating this issue "[...] You have reached your pull rate limit. You may increase the limit by authenticating and upgrading: https://www.docker.com/increase-rate-limit [...]", so this is not an OpenShift (OKD) error, but a limitation imposed by Docker whereby anonymous and free Docker Hub users are limited to 100~200 container image pull requests per six hours;
2 . For some reason this step tends to have errors due to problems in the used repositories. In case it fails you can try to delete the project `oc delete project wordpress-test` and try to create it again.

[Ref(s).: https://www.docker.com/increase-rate-limit ]

Track the build progress...

```
oc logs -f buildconfig/wordpress
```

... and wait for outputs similar to these...

```
Writing manifest to image destination
Storing signatures
Successfully pushed image-registry.openshift-image-registry.svc:5000/wordpress-test/wordpress@sha256:0acafe4f78ea4b6c3dda75837d47e6a4bb3b5d20b02c2597b77afa73ff1355cf
Push successful
```

Expose the service to create a route...

```
oc expose service/wordpress
```

Create a new app using the CentOS 7 MariaDB image with some environment variables...

```
oc new-app centos/mariadb-103-centos7 --name mariadb --env MYSQL_DATABASE=wordpress --env MYSQL_USER=wordpress --env MYSQL_PASSWORD=wordpress
```

## On Web Console

Open the Web Console and change from "Administrator" to "</> Developer" (top left corner "↓"), then on "Topology" select and click in "wordpress-test" project.

Click on the "wordpress" object, them on the link in the "Routes" section.

After accessing the indicated route, proceed as follows...

 * 1ST SCREEN
    You should see the WordPress setup config. Click "Let's go!".

 * 2ND SCREEN
    Fill the "Database Name" ("wordpress"), "Username" ("wordpress"), "Password" ("wordpress") and "Database Host" ("mariadb"). Click "Submit".

 * 3RD SCREEN
    Click "Run the installation"

 * 4TH SCREEN
    Fill the "Site Title" ("wp_test"), "Username" ("wp_test"), "Password" ("wp_test"), "Your Email" ("wp_test@fake.fake") and check "Confirm use of weak password". Click "Install WordPress".

 * 6TH SCREEN
    Click "Log In"

 * 7TH SCREEN
    Fill the "Username or Email Address" ("wp_test") and "Password" ("wp_test"). Click "Log In".

 * 8TH SCREEN
    Create/edit something if you want and/or click "View your site".

## Check the size of your NFS export (OKD_SERVICES)

It should be around 250~300MB in size...

```
du -sh /var/nfsshare/registry
```

... , so your persistent volume is working.

# Seeking help and helping others

Congratulations Dante! You've gone through all the nine circles of torment and installed OpenShift (OKD)! Wow!

Here are some resources available to help you...

To report issues, use the OKD Github repo ( https://github.com/openshift/okd ).

For support check out the "#openshift-users" channel on K8S (Kubernetes) Slack ( https://slack.k8s.io/ ).

The OKD Working Group ( https://github.com/openshift/community#okd-working-group-meetings ) meets bi-weekly to discuss the development and next steps. The meeting schedule and location are tracked in the openshift/community repo ( https://github.com/openshift/community/projects/1#card-28309038 ).

Google group for OKD-WG ( https://groups.google.com/forum/#!forum/okd-wg ).

---------------------------------------------------------------------

# KVM network - Create a "very private"/"very isolated" network

This type of network can be used for a "very private" or "very isolated" network, since it will not be possible for the virtual machines (guests) to communicate with the hypervisor (host) and the internet (WAN) through this network. However, this virtual network interface can be used for communication between virtual machines (guests).

**NOTE:** Tested on CentOS 8.

[Ref(s).: https://libvirt.org/formatnetwork.html#examplesNoGateway ]

## Create a new network config with no gateway addresses on KVM ("very private" or "very isolated") (HYPERVISOR)

### Create the network config

```
read -r -d '' FILE_CONTENT << 'HEREDOC'
BEGIN
<network>
  <name>okd_network</name>
  <uuid>[MY_NETWORK_UUID]</uuid>
  <bridge name='virbr[MY_NETWORK_NUMBER]' stp='on' delay='0'/>
  <mac address='52:54:00:[MY_NETWORK_MAC_FINAL]'/>
</network>

END
HEREDOC
echo -n "${FILE_CONTENT:6:-3}" > '/usr/share/libvirt/networks/okd_network.xml'
```

**Tag values...**
 * [MY_NETWORK_UUID] ("uuid" is OPTIONAL) - You can generate a new one at the URL https://www.uuidgenerator.net/version4 (version 4 UUID);
 * [MY_NETWORK_NUMBER] - We use the "virbr" prefix to follow the existing naming "convention". The suggested value is 1;
 * [MY_NETWORK_MAC_FINAL] ("mac" is OPTIONAL) - You can generate one at the URL https://miniwebtool.com/mac-address-generator/ . Use MAC address prefix "52:54:00" (is always the same for KVM), MAC address format with ":" and case "Lowercase".

### Add the new network definition XML file to libvirt

```
virsh net-define "/usr/share/libvirt/networks/okd_network.xml"
```

### Start the new network

```
virsh net-start okd_network
```

### Set the new network to automatically startup each time the KVM host is rebooted

```
virsh net-autostart okd_network
```

---------------------------------------------------------------------

# KVM Nested Virtualization - Virtualization Support or Hardware-Assisted Virtualization for guests

Nested Virtualization is a technique to run virtual machines in other virtual machines (more than one level of virtualization).

Hardware Virtualization Support or Hardware-Assisted Virtualization is a set of processor extensions that address issues with the virtualization of some privileged instructions and the performance of virtualized system memory. So Hardware Virtualization Support is required on the host processor.

Intel's implementation is called VT-x and AMD's implementation is called AMD-V. This feature is available in most current CPUs. However, this feature might be disabled in the BIOS.

**NOTE:** Tested on CentOS 8.

[Ref(s).: https://storpool.com/blog/nested-virtualization-with-kvm-and-opennebula ,
https://docs.fedoraproject.org/en-US/quick-docs/using-nested-virtualization-in-kvm/ ,
https://www.linux-kvm.org/page/Nested_Guests ]

## Enable Nested Virtualization (Intel VT-x) (HYPERVISOR)

### Check Hardware Virtualization Extensions

To make sure that Hardware Virtualization Extensions (Intel VT-X) are present on the host CPU and enabled in its BIOS you can use the following commands...

```
lscpu | grep Virtualization
```

... expected output is "Virtualization: VT-x".

**NOTES:**
 1. In this process we are only covering Intel's VT-X which is the most common. The process for AMD's AMD-V is very similar;
 2. The Hardware Virtualization Extensions also need to be enabled in the bios.

[Ref(s).: https://stackoverflow.com/a/56973830/3223785 ]

### Check if Nested Virtualization is already enabled on KVM (Intel VT-X)

For Intel processors use the command...

`
cat "/sys/module/kvm_intel/parameters/nested"
`

... expected output is "1" or "Y".

### If Nested Virtualization is disabled on KVM (Intel VT-X)

**NOTE:** The KVM kernel modules do not enable nesting by default, though your distribution may override this default.

To enable Nested Virtualization use this command...

```
read -r -d '' FILE_CONTENT << 'HEREDOC'
BEGIN
options kvm-intel nested=Y

END
HEREDOC
echo -n "${FILE_CONTENT:6:-3}" > '/etc/modprobe.d/kvm_intel.conf'
```

... and reboot the hypervisor (host).

## Enable Nested Virtualization (VIRTUAL_MACHINES)

### Setup in "virt-manager"

Open "virt-manager" on a desktop computer...

```
virt-manager
```

The configuration can be done according to the following guide...

* Select in the hypervisor (host) connection the virtual machine (guest).
    * NOTE: The virtual machine (guest) must be turned off.
    * Click with the second mouse button.
    * Click "Open" in the context menu.
    * A new window ("<VM_NAME> on QEMU/KVM: XXX.XXX.XXX.XXX") will appear.
        * Follow "View" > "Details".
            * Click on "CPUs" and on the "XML" tab look for the "<cpu>" element configuring it according to this template...
                ```
                  <cpu [...]>
                    [...]
                    <feature policy="require" name="vmx"/>
                  </cpu>
                ```
              ... adding the "<feature>" element with the appropriate parameters.
            * Click on "Apply".

[Ref(s).: https://www.reddit.com/r/VFIO/comments/inrlxc/intel_kvm_nested_hyperv_virtualization_in_a/gcxd88i?utm_source=share&utm_medium=web2x&context=3 ]

### Check Hardware Virtualization Extensions on virtual machines (guests)

Access the virtual machine's terminal and proceed with the same checks used for the hypervisor (host) in the section "Check Hardware Virtualization Extensions".

---------------------------------------------------------------------

# Setup Let's Encrypt Wildcard SSL Certificate with Nginx Reverse Proxy

The Let's Encrypt is a Certificate Authority (CA) that provides an easy way to obtain and install free TLS/SSL certificates, thus enabling encrypted HTTPS on web servers. It simplifies the process by providing a software client (Certbot) that tries to automate most (if not all) of the necessary steps, especially for Apache and Nginx.

A Nginx reverse proxy is an intermediary proxy service which takes a client request, passes it on to one or more servers, and subsequently delivers the server's response back to the client.

**NOTES:**
 * Tested on CentOS 8;
 * We will not cover here the Nginx reverse proxy installation and basic configuration. We will just cover how to create a Let's Encrypt wildcard SSL certificate and configure Nginx as a reverse proxy with it to the OpenShift (OKD) web resources. Therefore, the explanations provided here assume that you already have your Nginx reverse proxy installed and working.

## Setup Let's Encrypt Wildcard SSL Certificate (NGINX_REVERSE_PROXY)

### Create an "A" wildcard record in your DNS (external)

Create an "A" wildcard record in your DNS (external) as below...

MODEL

```
*.apps.mbr.<YOUR_DOMAIN>
```

EXAMPLE

```
*.apps.mbr.domain.abc
```

**NOTE:** In our DNS (external) we had to look for the section where "Type A" appears. Then we entered "*.apps.mbr.domain.abc" for "Entry" and our internet IP for "Value". This will vary according to each reality.

 ## Install the packages...

```
dnf install -y epel-release
dnf update -y
dnf install -y certbot python3-certbot-nginx
```

### Generate SSL Certificate...

MODEL

```
certbot certonly \
    --agree-tos \
    --email <YOUR_ADMIN_EMAIL> \
    --manual \
    --preferred-challenges=dns \
    -d *.apps.mbr.<YOUR_DOMAIN> \
    --server https://acme-v02.api.letsencrypt.org/directory
```

EXAMPLE

```
certbot certonly \
    --agree-tos \
    --email admin@anydomain.any \
    --manual \
    --preferred-challenges=dns \
    -d *.apps.mbr.domain.abc \
    --server https://acme-v02.api.letsencrypt.org/directory
```

You will receive a "TXT" record which you need to add to your DNS (external) server. The record will look as below...

```
[...]
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Please deploy a DNS TXT record under the name
_acme-challenge.apps.mbr.domain.abc with the following value:

dL2prHMK152EdcZkcvUA18rsqCJihKoBIkXxyMK3VH5

Before continuing, verify the record is deployed.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Press Enter to Continue
[...]
```

**NOTE:** In our DNS (external) we had to look for the section where the "Type TXT" appears. Then we entered "_acme-challenge.apps.mbr.domain.abc" for "Entry" and "dL2prHMK152EdcZkcvUA18rsqCJihKoBIkXxyMK3VH5" for "Value". This will vary according to each reality.

Once the record has been deployed, press Enter to obtain the certificate. You should get a feedback like below...

```
[...]
Waiting for verification...
Cleaning up challenges

IMPORTANT NOTES:
 - Congratulations! Your certificate and chain have been saved at:
   /etc/letsencrypt/live/apps.mbr.domain.abc/fullchain.pem
   Your key file has been saved at:
   /etc/letsencrypt/live/apps.mbr.domain.abc/privkey.pem
   Your certificate will expire on 2021-10-19. To obtain a new or
   tweaked version of this certificate in the future, simply run
   certbot again. To non-interactively renew *all* of your
   certificates, run "certbot renew"
 - If you like Certbot, please consider supporting our work by:

   Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
   Donating to EFF:                    https://eff.org/donate-le
```

Your new certificates will be in the folder...

MODEL

```
ls /etc/letsencrypt/live/apps.mbr.<YOUR_DOMAIN>
```

EXAMPLE

```
ls /etc/letsencrypt/live/apps.mbr.domain.abc
```

## Add a job (crontab) to renew the certificate (NGINX_REVERSE_PROXY)

As the certificate expires every 3 months, we need to add a job (crontab) to renew the certificate automatically, so the user does not face an invalid digital certificate screen.

Check if there is already a schedule with the command...

```
crontab -l
```

... if there is no job, use the command below to add the schedule...

```
(crontab -l 2>/dev/null; printf "PATH=$PATH\n30 4 * * * /usr/bin/certbot renew --quiet --no-self-upgrade\n") | crontab -
```

... if there is already a job, use the command (behaves like vi/vim)...

```
crontab -e
```

...and add the line...

```
30 4 * * * /usr/bin/certbot renew --quiet --no-self-upgrade
```

**IMPORTANT:** Since crontab does not have the correct shell variables, we need to add the current user (root) path definition to the crontab jobs. In this way add (if it doesn't already exist) as the first line (before any scheduling) the output of the command below...

```
echo "PATH=$PATH"
```

... that will be something like this...

```
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
```
.

## Create configuration to Nginx reverse proxy OpenShift (OKD) (NGINX_REVERSE_PROXY)

### Create a configuration file for Nginx reverse proxy

Adjusting the settings in the "SETUP PARAMETERS" section (below) according to your reality and according to its guidelines...

**NOTE:** After adjusting the settings in the "SETUP PARAMETERS" section (below), copy all the content and paste it into the terminal. The commands below will result in the creation of a configuration file for the Nginx reverse proxy with the settings in the "SETUP PARAMETERS" section.

```
# > -------------------
# SETUP PARAMETERS

# The domain for the OpenShift (OKD) cluster.
OKD_DOMAIN="domain.abc"

# First 3 octets of OpenShift (OKD) internet network.
INT_LAN_24="10.2.0"

# Last octet of the OKD_SERVICES server IP.
OKD_SERVICES_IL_LST_OCT="18"

# Path where the Nginx reverse proxy configuration file should be created.
NGINX_RP_S_AVAL_PATH="/etc/nginx/sites-available"

# < -------------------

# > -------------------
# Nginx reverse proxy configuration file

read -r -d '' FILE_CONTENT << HEREDOC
BEGIN
server {
    access_log /var/log/nginx/apps.mbr.$OKD_DOMAIN-ssl-access.log;
    error_log /var/log/nginx/apps.mbr.$OKD_DOMAIN-ssl-error.log;
    server_name *.apps.mbr.$OKD_DOMAIN;

    location / {
        proxy_pass https://$INT_LAN_24.$OKD_SERVICES_IL_LST_OCT:443;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_ssl_name \$host;
        proxy_ssl_server_name on;
    }

    listen 443;
    ssl_certificate /etc/letsencrypt/live/apps.mbr.$OKD_DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/apps.mbr.$OKD_DOMAIN/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}

server {
    access_log /var/log/nginx/apps.mbr.$OKD_DOMAIN-access.log;
    error_log /var/log/nginx/apps.mbr.$OKD_DOMAIN-error.log;
    server_name ~^(?<subdomain>[^.]+).apps.mbr.$OKD_DOMAIN;

    # Redirect HTTP routes to OpenShift (OKD) subdomains (routes) known as HTTPS.
    if (\$subdomain = "\\
            alertmanager-main-openshift-monitoring|\\
            canary-openshift-ingress-canary|\\
            console-openshift-console|\\
            downloads-openshift-console|\\
            grafana-openshift-monitoring|\\
            oauth-openshift|\\
            prometheus-k8s-openshift-monitoring|\\
            thanos-querier-openshift-monitoring\\
            ") {
        # [Ref(s).: https://stackoverflow.com/a/45504231/3223785 ]

        return 301 https://\$host\$request_uri;
    }

    # Redirection to HTTPS is not possible for all routes because some OpenShift
    # (OKD) routes use HTTP.
    location / {
        proxy_pass http://$INT_LAN_24.$OKD_SERVICES_IL_LST_OCT:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    listen 80;
}

END
HEREDOC
echo -n "${FILE_CONTENT:6:-3}" > "$NGINX_RP_S_AVAL_PATH/apps.mbr.$OKD_DOMAIN"

# < -------------------
```

**NOTES:**
1. Note that the most important configuration item above is `proxy_ssl_name $host;`, without it the "oauth-openshift.apps.mbr.<YOUR_DOMAIN>" route will not work;
2. There are different ways to maintain and organize settings for an Nginx reverse proxy. Our approach uses the "sites-available/sites-enabled" scheme and symbolic links.

[Ref(s).: https://stackoverflow.com/q/68538099/3223785 ]

Restart the service "nginx" (Nginx) and watch its log in sequence...

```
systemctl restart nginx.service
journalctl -u nginx.service --no-pager | less +F
```

--------

**TIP:** If the DNS (external) configuration with wildcard is correct, any subdomain should get an answer according to the examples below. To test perform these commands on your desktop...

```
ping -c 2 any.apps.mbr.domain.abc
ping -c 2 other.apps.mbr.domain.abc
ping -c 2 subdomain.apps.mbr.domain.abc
ping -c 2 that.apps.mbr.domain.abc
ping -c 2 exists.apps.mbr.domain.abc
ping -c 2 for.apps.mbr.domain.abc
ping -c 2 your.apps.mbr.domain.abc
ping -c 2 domain.apps.mbr.domain.abc
```
.

--------

---------------------------------------------------------------------

# OpenLDAP (LDAP) e OpenShift (OKD) - Configuring OpenLDAP (LDAP) as identity provider for OpenShift (OKD)

Here we explain how to configure the OpenLDAP (LDAP) as identity provider to validate user names (UIDs) and passwords against an LDAPv3 server, using simple bind authentication.

The LDAP (Lightweight Directory Access Protocol) is an open, vendor-neutral, industry standard application protocol for accessing and maintaining distributed directory information services over an internet protocol network.

OpenLDAP (LDAP) is a free, open-source implementation of the LDAP Protocol developed by the OpenLDAP (LDAP) Project.

**NOTE:** Tested on CentOS 8.

[Ref(s).: https://docs.okd.io/latest/authentication/identity_providers/configuring-ldap-identity-provider.html ,
https://access.redhat.com/documentation/en-us/openshift_container_platform/4.7/html/authentication_and_authorization/configuring-identity-providers#configuring-ldap-identity-provider .
https://github.com/openshift/okd/discussions/797 ,
https://www.ammeonsolutions.com/insights/2020/3/2/configuring-openshift-v41-ldap-configuration .
https://blog.pichuang.com.tw/20200427-openshift-with-coreos-part-5/ ,
https://www.linuxstudio.com/rh/apps-certificates.html ]

## Avoid "error: x509: certificate signed by unknown authority" (OKD_SERVICES)

The OpenShift (OKD) cluster has a "stalking mania" and doesn't even believe in its own resources. So we have to extract the certificate used by its access API to avoid the above error.

### List pods used by the access API

List the pods used by the cluster's access API...

```
oc get pods -n openshift-authentication
```

... and take note of the identifier of one of them (e.g.: "oauth-openshift-56678dbbfb-dzq2j").

Extract the certificate...

MODEL

```
cd "/etc/pki/ca-trust/source/anchors"
oc rsh -n openshift-authentication <OAUTH_OPENSHIFT_POD_NAME> cat /run/secrets/kubernetes.io/serviceaccount/ca.crt > ingress-ca.crt
```

EXAMPLE

```
cd "/etc/pki/ca-trust/source/anchors"
oc rsh -n openshift-authentication oauth-openshift-56678dbbfb-dzq2j cat /run/secrets/kubernetes.io/serviceaccount/ca.crt > ingress-ca.crt
```

... and add it as a trusted Certificate Authority (CA)...

```
update-ca-trust extract
```

[Ref(s).: https://www.mankier.com/8/update-ca-trust ]

## OpenLDAP (LDAP) as identity provider (OKD_SERVICES)

### Configure the OpenLDAP (LDAP) as identity provider

To specify an identity provider, you must create a custom resource (CR) that describes that identity provider and add it to the cluster.

Configure the custom resource (CR)...

EXAMPLE

```
cat <<EOF | oc apply -f -
---
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: ldapidp
    mappingMethod: claim
    type: LDAP
    ldap:
      attributes:
        id:
        - dn
        email:
        - mail
        name:
        - cn
        preferredUsername:
        - uid
      bindDN: ""
      insecure: true
      url: "ldap://10.2.0.5:389/dc=domain,dc=abc?uid?sub?(pgmemberof=cn=openshift_okd,ou=groups,dc=domain,dc=abc)"
EOF
```

**NOTES:**

 1. In the example above we do not use LDAPS (LDAP over SSL, port 636) nor a bind DN with password. If this is not your case see the documentation at https://docs.okd.io/latest/authentication/identity_providers/configuring-ldap-identity-provider.html for more details;
 2. For the "url" parameter we are using a "memberOf" ("pgmemberof") group filter, so that only users of the "openshift_okd" group can log into OpenShift (OKD). Here's another valid model/example...

MODEL

```
url: "<LDAP_PROTOCOL>://<LDAP_SRV_NM_OR_IP>:<LDAP_SRV_PORT>/<LDAP_BASE_DN>?<LDAP_URI_PARAMETERS>"
```

EXAMPLE

```
url: "ldap://10.2.0.5:389/dc=domain,dc=abc?uid"
```
.

**PLUS:** If you use POSIX Groups in your OpenLDAP (LDAP) and want to use them as access groups (see parameter "pgmemberof" above), then you might want to take a look at this solution https://github.com/eduardolucioac/psx-grp-flt .

### Test the OpenLDAP (LDAP) as identity provider

Log in as an OpenLDAP (LDAP) user...

MODEL

```
oc login -u <LDAP_USER_UID>
```

EXAMPLE

```
oc login -u myusruid
```

Check the logged in user...

```
oc whoami
```

Logout...

```
oc logout
```

Return to the default administrator user...

```
oc login -u "system:admin"
```

Give "cluster-admin" access to an OpenLDAP (LDAP) user...

MODEL

```
oc adm policy add-cluster-role-to-user cluster-admin <LDAP_USER_UID>
```

EXAMPLE

```
oc adm policy add-cluster-role-to-user cluster-admin myusruid
```

**NOTE:** Now, the OpenLDAP (LDAP) user has cluster administrator level access.

## Test access to the Web Console

From your desktop browser, test access to the Web Console using an URL like this example...

```
https://console-openshift-console.apps.mbr.domain.abc
```

... and on the first login screen use the "ldapidp" option and then an OpenLDAP (LDAP) user and password.

--------

**TIP:** If you change an user CN (change the "Last Name" or "First Name", for example) in OpenLDAP (LDAP), will be necessary to "delete" this user in OpenShift (OKD)...

MODEL

```
oc delete user <LDAP_USER_UID>
```

EXAMPLE

```
oc delete user myusruid
```

... otherwise the error "Error from server (InternalError): Internal error occurred: unexpected response: 500" will occur when trying to login via command `oc login -u <LDAP_USER_UID>` and will also fail when trying to login to the Web Console.

This solution implies losing resources linked to the deleted user. Then assess whether this is the best solution for you.

[Ref(s).: https://docs.openshift.com/enterprise/3.2/admin_guide/manage_users.html#managing-users-deleting-a-user ]

--------

---------------------------------------------------------------------

# About

okd_bare_metal 🄯 BSD-3-Clause  
Eduardo Lúcio Amorim Costa  
Brazil-DF  
https://www.linkedin.com/in/eduardo-software-livre/

<img border="0" alt="Brazil-DF" src="http://upload.wikimedia.org/wikipedia/commons/thumb/6/6d/Map_of_Brazil_with_flag.svg/180px-Map_of_Brazil_with_flag.svg.png" height="15%" width="15%"/>

---------------------------------------------------------------------
