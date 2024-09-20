services = ["sqladmin.googleapis.com", "bigquery.googleapis.com","servicenetworking.googleapis.com"]

region="us-central1"

project="steam-insight-430414-n9"

vpc_on_prem="vpc-on-prem"

vpc_google="vpc-google"

subnet_on_prem="subnet-on-prem"

subnet_google="subnet-google"

subnet_cidr_on_prem="10.1.0.0/16"

subnet_cidr_google="10.2.0.0/16"

router_on_prem="router-on-prem"

router_google="router-google"

router_asn_on_prem=64514

router_asn_google=64515

vpn_ha_gwy_on_prem = "vpn-ha-gwy-onprem"

vpn_ha_gwy_google = "vpn-ha-gwy-google"

tunnels_onprem = ["vpn-tunnel-onprem-1","vpn-tunnel-onprem-2"]

tunnels_google = ["vpn-tunnel-google-1","vpn-tunnel-google-2"]

secret_message = "secret message"

router_interface_onprem = [ "router-interface-onprem-1","router-interface-onprem-2" ]

router_interface_google = [ "router-interface-google-1","router-interface-google-2" ]

router_peer_onprem = [ "router-peer-onprem-1","router-peer-onprem-2" ]

router_peer_google = [ "router-peer-google-1","router-peer-google-2" ]

onprem_router_ip_range = ["169.254.0.1/30", "169.254.1.2/30"]

onprem_router_peer_ip_address = ["169.254.0.2","169.254.1.1"]

google_router_ip_range = ["169.254.0.2/30", "169.254.1.1/30"]

google_router_peer_ip_address = ["169.254.0.1","169.254.1.2"]
