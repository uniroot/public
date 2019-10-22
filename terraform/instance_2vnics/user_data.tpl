#cloud-config

write_files:
  # Create file to be used when enabling ip forwarding
  - path: /etc/sysctl.d/98-ip-forward.conf
    content: |
      net.ipv4.ip_forward = 1

runcmd:
  # Run firewall commands to enable masquerading and port forwarding
  # Enable ip forwarding by setting sysctl kernel parameter
  - firewall-offline-cmd --direct --add-rule ipv4 filter FORWARD 0 -i ens3 -j ACCEPT
  - firewall-offline-cmd --direct --add-rule ipv4 filter FORWARD 0 -i ens5 -j ACCEPT
  - /bin/systemctl restart firewalld
  - sysctl -p /etc/sysctl.d/98-ip-forward.conf
  # Get the config shell if possible to access the internet or for osedevelopment
  - https_proxy=10.188.53.53:80 wget -O /usr/local/bin/secondary_vnic_all_configure.sh https://raw.githubusercontent.com/cgong-github/oci/automation/secondary_vnic_all_configure.sh
