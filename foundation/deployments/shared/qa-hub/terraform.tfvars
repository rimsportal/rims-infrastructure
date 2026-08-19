location            = "centralindia"
location_short_name = "cin"
brand               = "RIMS"
brand_short_name    = "rims"
managed_by          = "Terraform"

# Hub address space. Must not overlap any spoke.
hub_address_space = ["10.0.0.0/24"]

# AzureBastionSubnet is reserved now (min /26) for the Phase 2 Bastion; no
# Bastion host is deployed yet. snet-shared is spare capacity for future hub
# services (firewall, DNS resolver, self-hosted runner, etc.).
hub_subnets = {
  AzureBastionSubnet = { cidr = "10.0.0.0/26" }
  snet-shared        = { cidr = "10.0.0.64/26" }
}
