/*
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "compartment_ocid" {}
variable "region" {}
variable "ssh_public_key" {}
# Choose an Availability Domain
variable "AD" {
    default = "3"
}

variable "InstanceShape" {
    default = "VM.Standard1.2"
}

variable "InstanceImageDisplayName" {
    default = "Oracle-Linux-7.7-2019.09.25-0"
}

variable "vcn_cidr" {
    default = "10.0.0.0/16"
}

variable "mgmt_subnet_cidr" {
    default = "10.0.0.0/24"
}

variable "private_subnet_cidr" {
    default = "10.0.1.0/24"
}
*/

/* 
provider "oci" {
    tenancy_ocid = "${var.tenancy_ocid}"
    user_ocid = "${var.user_ocid}"
    fingerprint = "${var.fingerprint}"
    private_key_path = "${var.private_key_path}"
    region = "${var.region}"
}
*/

data "oci_identity_availability_domains" "ADs" {
    compartment_id = "${var.tenancy_ocid}"
}

# Gets the OCID of the image. This technique is for example purposes only. 
# The results of oci_core_images may
# change over time for Oracle-provided images, so the only sure 
# way to get the correct OCID is to supply it directly.
data "oci_core_images" "OLImageOCID" {
    compartment_id = "${var.compartment_ocid}"
    display_name = "${var.InstanceImageDisplayName}"
}

resource "oci_core_instance" "Zonstance" {
    availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}"
    compartment_id = "${var.compartment_ocid}"
    display_name = "Zonstance"

    # image = "${lookup(data.oci_core_images.OLImageOCID.images[0], "id")}"
    shape = "${var.InstanceShape}"
    subnet_id = "${var.subnet_id}"

    source_details {
        source_id = "${lookup(data.oci_core_images.OLImageOCID.images[0], "id")}"
        source_type = "image"
    }
    metadata = {
        ssh_authorized_keys = "${var.ssh_public_key}"
        user_data = "${base64encode(file("./user_data.tpl"))}"
    }

    timeouts {
        create = "10m"
    }
}

# Gets a list of VNIC attachments on the instance
data "oci_core_vnic_attachments" "ZonstanceVnics" {
    compartment_id = "${var.compartment_ocid}"
    availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}"
    instance_id = "${oci_core_instance.Zonstance.id}"
}

# Gets the OCID of the first (default) vNIC on the instance
data "oci_core_vnic" "ZonstanceVnic" {
        vnic_id = "${lookup(data.oci_core_vnic_attachments.ZonstanceVnics.vnic_attachments[0],"vnic_id")}"
}

data "oci_core_private_ips" "FirstPrivateIPs" {
    ip_address = "${data.oci_core_vnic.ZonstanceVnic.private_ip_address}"
    subnet_id = "${var.subnet_id}"
    #vnic_id =  "${data.oci_core_vnic.NatInstanceVnic.id}"
}
/*
output "Private_IP" {
  value = "${oci_core_private_ips.FirstPrivateIPs.ip_address}"
}
*/

# Attach second VNIC
resource "oci_core_vnic_attachment" "SecondaryVnicAttachment" {
  instance_id = "${oci_core_instance.Zonstance.id}"
  # Create a VNIC with given subnet   
  create_vnic_details {
    subnet_id = "${var.privatesubnet2_id}"
    assign_public_ip = false
    skip_source_dest_check = true
  }
  /* 
  # Use file provisioner or wget the script from OCI within instance, please see
  # userdata.tpl 
  provisioner "file" {
    source      = "scripts/secondary_vnic_all_configure.sh"
    destination = "/tmp/secondary_vnic_all_configure.sh"
    connection {
      host = "${oci_core_instance.Zonstance.private_ip}"
      type = "ssh"
      user = "opc"
      private_key = "${file(var.ssh_private_key_path)}"
      timeout = "3m"
    }
  }
  */
  #count = 1
  provisioner "remote-exec" {
      inline = [
        "sudo iptables -F",
        "sudo iptables -X",
        "sleep 6",
        "sudo chmod 766 /usr/local/bin/secondary_vnic_all_configure.sh",
        "sudo /usr/local/bin/secondary_vnic_all_configure.sh -c -e $(oci-metadata -j -g privateIp --value-only | tail -1) $(oci-metadata -j -g vnicId --value-only | tail -1)",
        "sudo firewall-offline-cmd --direct --add-rule ipv4 filter FORWARD 0 -i ens5 -j ACCEPT"
      ]
    connection {
      host = "${oci_core_instance.Zonstance.private_ip}"
      type = "ssh"
      user = "opc"
      private_key = "${file(var.ssh_private_key_path)}"
      timeout = "3m"
    }
  }
}

##### Get the ip of 2nd VNIC #########
# Gets a list of vNIC attachments on the instance
data "oci_core_vnic_attachments" "ZonstanceVnics_2" {
    compartment_id = "${var.compartment_ocid}"
    availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}"
    instance_id = "${oci_core_instance.Zonstance.id}"
}

# Gets the OCID of the 2nd (attached) vNIC on the instance
data "oci_core_vnic" "ZonstanceVnic_2" {
        vnic_id = "${lookup(data.oci_core_vnic_attachments.ZonstanceVnics_2.vnic_attachments[0],"vnic_id")}"
}
/*
data "oci_core_private_ips" "SecondPrivateIPs" {
    ip_address = "${data.oci_core_vnic.ZonstanceVnic_2.private_ip_address}"
    # subnet_id = "${var.privatesubnet2_id}"
    vnic_id = "${data.oci_core_vnic.ZonstanceVnic_2.vnic_id}"
}
*/
output "Second_Private_IP" {
  value = "${data.oci_core_vnic.ZonstanceVnic_2.private_ip_address}"
}
