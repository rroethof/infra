# variables.pkr.hcl

# vSphere-specifieke instellingen
variable "vsphere_server" {
  type    = string
  default = ""
  # Dit is het IP-adres of de hostname van de vSphere-server waar de VM wordt aangemaakt.
}

variable "vsphere_user" {
  type    = string
  default = ""
  # De gebruikersnaam voor authenticatie op de vSphere-server.
}

variable "vsphere_password" {
  type    = string
  default = ""
  # Het wachtwoord voor authenticatie op de vSphere-server.
}

variable "vsphere_datacenter" {
  type    = string
  default = ""
  # De naam van het datacenter in vSphere waar de VM wordt geplaatst.
}

variable "cluster" {
  type    = string
  default = ""
  # De naam van het cluster in vSphere waar de VM wordt gehost.
}

variable "datastore" {
  type    = string
  default = ""
  # De naam van de datastore waar de VM-schijven worden opgeslagen.
}

variable "network_name" {
  type    = string
  default = ""
  # De naam van het netwerk waar de VM op wordt aangesloten.
}

variable "vm_name" {
  type = string
  default = ""
  # De naam van de virtuele machine zoals deze in vSphere zal verschijnen.
}

variable "host_name" {
  type = string
  default = ""
  # De hostname van de VM binnen het netwerk (bijv. "server01").
}

variable "domain_name" {
  type        = string
  description = "Domain name for the VM."
  default     = "sds.internal"
  # Het domein van de VM (bijv. "sds.internal" als standaard interne domeinnaam).
}

variable "vm_cpus" {
  type = number
  default = 1
  # Het aantal CPU's dat aan de VM wordt toegewezen (standaard 1).
}

variable "vm_ram" {
  type = number
  default = 1024
  # Het RAM-geheugen in MB dat aan de VM wordt toegewezen (standaard 1024 MB = 1 GB).
}

variable "vm_disk_size" {
  type = number
  default = 6144
  # De grootte van de schijf in MB die aan de VM wordt toegewezen (standaard 6144 MB = 6 GB).
}

variable "ssh_username" {
  type = string
  default = ""
  # De gebruikersnaam voor SSH-toegang tot de VM na installatie.
}

variable "ssh_password" {
  type = string
  default = ""
  # Het wachtwoord voor SSH-toegang tot de VM na installatie.
}

variable "iso_paths" {
  type = list(string)
  default = []
  # Een lijst met paden naar de ISO-bestanden die gebruikt worden voor de installatie.
}

variable "iso_checksum" {
  type = string
  default = ""
  # De checksum (bijv. SHA256) van de ISO om de integriteit te verifiëren.
}

variable "vm_guest_id" {
  type = string
  default = "debian12_64Guest"
  # De gast-ID voor vSphere die het besturingssysteem aangeeft (standaard Debian 12 64-bit).
}

variable "vm_ip" {
  type        = string
  description = "Static IP address for the VM during installation. If left empty (default), DHCP will be used."
  default     = ""
  # Het statische IP-adres voor de VM tijdens installatie; leeg laat DHCP toe.
}

variable "vm_netmask" {
  type        = string
  description = "Static netmask for the VM (e.g., 255.255.255.0). Required if vm_ip is set."
  default     = "255.255.255.0"
  # Het subnetmasker voor de VM (standaard 255.255.255.0); vereist bij statisch IP.
}

variable "vm_gateway" {
  type        = string
  description = "Static gateway for the VM. Required if vm_ip is set."
  default     = ""
  # Het gateway-adres voor de VM; vereist bij statisch IP.
}

variable "vm_nameservers" {
  type        = string
  description = "Space-separated list of DNS servers for the VM (e.g., \"8.8.8.8 8.8.4.4\"). Required if vm_ip is set."
  default     = "192.168.250.10 192.168.250.11"
  # Een spatie-gescheiden lijst van DNS-servers voor de VM; vereist bij statisch IP.
}

variable "preseed_ip" {
  type        = string
  description = "Static gateway for the VM. Required if vm_ip is set."
  default     = ""
  # Het IP-adres waar de preseed-configuratie wordt gehost; vereist bij statisch IP.
}

# Lokalisatie-instellingen
variable "language" {
  type    = string
  default = "en"
  # De taal voor de installatie (standaard "en" voor Engels).
}

variable "country" {
  type    = string
  default = "NL"
  # Het land voor de installatie (standaard "NL" voor Nederland).
}

variable "locale" {
  type    = string
  default = "en_NL.UTF-8"
  # De locale-instelling (standaard "en_NL.UTF-8" voor Engels met Nederlandse instellingen).
}

variable "keyboard" {
  type    = string
  default = "nl"
  # De toetsenbordindeling (standaard "nl" voor Nederlands).
}

# Klok-instellingen
variable "timezone" {
  type    = string
  default = "Europe/Amsterdam"
  # De tijdzone voor de VM (standaard "Europe/Amsterdam").
}

variable "system_clock_in_utc" {
  type    = bool
  default = false
  # Of de systeemklok in UTC is ingesteld (standaard "false" voor lokale tijd, bijv. bij dual-boot met Windows).
}

# Pakket-instellingen
variable "mirror" {
  type    = string
  default = "ftp.nl.debian.org"
  # De hostname van de Debian-pakketspiegel (standaard "ftp.nl.debian.org" voor Nederland).
}