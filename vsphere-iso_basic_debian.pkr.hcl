# vsphere-iso_basic_debian.pkr.hcl
locals {
  # Als een statisch IP-adres (var.vm_ip) is opgegeven, stel dan de netwerkconfiguratie voor de boot command samen.
  # Laat het anders leeg om DHCP te gebruiken.
  boot_command_network_args = var.vm_ip != "" ? "netcfg/disable_dhcp=true netcfg/get_ipaddress=${var.vm_ip} netcfg/get_netmask=${var.vm_netmask} netcfg/get_gateway=${var.vm_gateway} netcfg/get_nameservers=${var.vm_nameservers}" : ""
}

source "vsphere-iso" "this" {
  vcenter_server            = var.vsphere_server
  username                  = var.vsphere_user
  password                  = var.vsphere_password
  datacenter                = var.vsphere_datacenter
  cluster                   = var.cluster
  insecure_connection       = true

  vm_name                   = var.vm_name
  guest_os_type             = var.vm_guest_id

  ssh_username              = var.ssh_username
  ssh_password              = var.ssh_password
  ssh_timeout               = "20m"

  CPUs                      = var.vm_cpus
  RAM                       = var.vm_ram
  RAM_reserve_all           = true

  disk_controller_type      = ["pvscsi"]
  datastore                 = var.datastore
  storage {
    disk_size               = var.vm_disk_size
    disk_thin_provisioned   = true
  }
  # Dit is de correcte variabele voor het pad naar je ISO.
  iso_paths                 = var.iso_paths
  # De checksum is hier toegevoegd, nu kan Packer hem lezen uit je variabelenbestand.
  iso_checksum              = var.iso_checksum

  network_adapters {
    network                 =  var.network_name
    network_card            = "vmxnet3"
  }

  # We gebruiken een preseed-bestand voor een onbeheerde Debian-installatie.
  # Packer start een lokale HTTP-server om dit bestand aan de VM te serveren.
  http_directory            = "http"
  # Dit dwingt Packer om poort 8081 te gebruiken.
  http_port_min = 8081
  http_port_max = 8081

  boot_command = [
    "<wait><wait><wait>c<wait><wait><wait>",
    "linux /install.amd/vmlinuz ",
    "auto=true ",
    "url=http://${var.preseed_ip}:8081/preseed.cfg ",
    "hostname=${var.host_name} ",
    "domain=${var.domain_name} ",
    "interface=auto ",
    "netcfg/get_hostname=${var.host_name} netcfg/get_domain=${var.domain_name} ",
    "${local.boot_command_network_args} ",
    "vga=788 noprompt quiet --<enter>",
    "initrd /install.amd/initrd.gz<enter>",
    "boot<enter>"
  ]

  shutdown_command    = ""
  convert_to_template = false
  firmware            = "efi"
}

build {
  sources  = [
    "source.vsphere-iso.this"
  ]

  provisioner "ansible" {
    user = var.ssh_username
    # wachtwoord = var.ssh_password
    playbook_file = "./ansible/playbook.yml" # Pas dit aan naar de locatie van jouw playbook!
    ansible_env_vars = ["ANSIBLE_HOST_KEY_CHECKING=False"]
    # Optioneel: als je de roles niet lokaal downloadt, maar door Packer wilt laten beheren
    # Dit kan problemen geven met specifieke galaxy roles. Lokaal downloaden is robuuster.
    # galaxy_file = "./ansible/requirements.yml"
    roles_path = "./ansible/roles" # Als je ze hier handmatig plaatst
  }

}