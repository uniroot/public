// Refer: https://github.com/terraform-providers/terraform-provider-oci/blob/master/examples/compute/vnic/vnic.tf

variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "compartment_ocid" {}
variable "region" {}
variable "ssh_public_key" {}
variable "instance_id" {
    default = "ocid1.instance.oc1.phx.anyhqljtgj4tlxyc3stcfa4lkbwc7iemerx2ixgr72l5h3dwohafpzb6dada"
}
# Choose an Availability Domain
variable "AD" {
    default = "3"
}

# Subnet: App-AD3-phx.sub 
variable "subnet_id" {
    default = "ocid1.subnet.oc1.phx.aaaaaaaajdeesxgsituk67ykknwxspjk2fbxqekzqmcvrmdis7nebebga2yq"
}
variable "privatesubnet2_id" {
    default = "ocid1.subnet.oc1.phx.aaaaaaaavzaqxjs6xtac6em4lgls23apq6fpoilxi66re7yxvdbp3b4h3hna"
}

variable "InstanceShape" {
    default = "VM.Standard1.2"
}

variable "InstanceImageDisplayName" {
    default = "Oracle-Linux-7.7-2019.09.25-0"
}

provider "oci" {
    tenancy_ocid = "${var.tenancy_ocid}"
    user_ocid = "${var.user_ocid}"
    fingerprint = "${var.fingerprint}"
    private_key_path = "${var.private_key_path}"
    region = "${var.region}"
}

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
/* Not correct -- the following, so commented out 
data "oci_core_private_ips" "FirstPrivateIPs" {
    # ip_address = "${data.oci_core_vnic.ZonstanceVnic.private_ip_address}"
    subnet_id = "${var.subnet_id}"
    # vnic_id =  "${data.oci_core_vnic.ZonstanceVnic.vnic_id}"
}

output "Private_IP1" {
  value = "${data.oci_core_private_ips.FirstPrivateIPs.private_ips[0].ip_address}"
  # value = "${data.oci_core_vnic_attachments.ZonstanceVnics.vnic_attachments[0]}"
}

data "oci_core_private_ips" "SecondPrivateIPs" {
    subnet_id = "${var.privatesubnet2_id}"
}

output "Private_IP2" {
  value = "${data.oci_core_private_ips.SecondPrivateIPs.private_ips[0].ip_address}"
}
*/ 
# Gets a list of VNIC attachments on the instance
data "oci_core_vnic_attachments" "ZonstanceVnics" {
    compartment_id = "${var.compartment_ocid}"
    availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1],"name")}"
    instance_id = "${var.instance_id}"
}

# Gets the OCID of the first (default) vNIC on the instance
data "oci_core_vnic" "ZonstanceVnic" {
        vnic_id = "${lookup(data.oci_core_vnic_attachments.ZonstanceVnics.vnic_attachments[0],"vnic_id")}"
}

data "oci_core_private_ips" "FirstPrivateIP" {
    ip_address = "${data.oci_core_vnic.ZonstanceVnic.private_ip_address}"
    subnet_id = "${var.subnet_id}"
    # vnic_id =  "${data.oci_core_vnic.ZonstanceVnic.vnic_id}"
}

output "Private_IP1_1" {
  value = "${data.oci_core_private_ips.FirstPrivateIP.ip_address}"
  # value = "${data.oci_core_vnic_attachments.ZonstanceVnics.vnic_attachments[0]}"
}
/*
# Output the result
data "template_file" "vnic_ids" {
  count = "${length(data.oci_core_vnic_attachments.ZonstanceVnics.vnic_attachments)}"
  template = "${lookup(data.oci_core_vnic_attachments.ZonstanceVnics.vnic_attachments[count.index], "vnic_id")}"
}

output "show-all-vNIC-ids" {
  value = "${data.template_file.vnic_ids.*.rendered}"
}
*/
data "oci_core_vnic" "instance_vnics" {
  count = "${length(data.oci_core_vnic_attachments.ZonstanceVnics.vnic_attachments)}"
  vnic_id = "${element(data.oci_core_vnic_attachments.ZonstanceVnics.vnic_attachments.*.vnic_id, count.index)}"
}
output "private_ip_addresses" {
  value = "${data.oci_core_vnic.instance_vnics.*.private_ip_address}"
}

data "oci_core_private_ips" "test_ips" {
  count = "${length(data.oci_core_vnic_attachments.ZonstanceVnics.vnic_attachments)}"
  vnic_id = "${element(data.oci_core_vnic_attachments.ZonstanceVnics.vnic_attachments.*.vnic_id, count.index)}"
}
/*
output "test_private_ips" {
  value = "${data.oci_core_private_ips.test_ips.*.private_ips}"
}
*/
data "oci_core_private_ip" "test_private_ip" {
    #Required
    private_ip_id = "${data.oci_core_private_ips.test_ips[1].private_ips[0].id}"
}

output "foo" {
    value = "${data.oci_core_private_ip.test_private_ip.ip_address}"
}

data "template_file" "test_private_ip_s" {
    count = "${length(data.oci_core_vnic_attachments.ZonstanceVnics.vnic_attachments)}"
    #Required
    template = "$(data.oci_core_private_ips.test_ips[count.index])"
}

output "bar" {
    value = "${data.template_file.test_private_ip_s.*.rendered}"
}    
