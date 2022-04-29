# !/usr/bin/env python3

# https://github.com/jktr/hcloud-packer-templates/blob/e71151cdb11c120df1c2b1e84106614d299ef1d4/files/hcloud-metadata

import yaml
import json
import sys

from urllib.request import urlopen

metadata = "http://169.254.169.254/hetzner/v1/metadata"
networks = "http://169.254.169.254/hetzner/v1/metadata/private-networks"

with urlopen(metadata) as metadata:
    metadata = yaml.safe_load(metadata)
    metadata_net = metadata["network-config"]["config"][0]

with urlopen(networks) as networks:
    networks = yaml.safe_load(networks)

data = {
    "network": {
        "nameservers": [],
        "mac_address": metadata_net["mac_address"],
        "ipv4_address": metadata["public-ipv4"],
        "ipv4_subnet": metadata["public-ipv4"] + "/32",
        "ipv4_gateway": "172.31.1.1",
        "private": networks,
    },
    "hostname": metadata["hostname"],
    "instance_id": metadata["instance-id"],
    "ssh_keys": [x.rstrip() for x in metadata["public-keys"]],
}

for subnet in metadata_net["subnets"]:
    if "dns_nameservers" in subnet:
        data["network"]["nameservers"] += subnet["dns_nameservers"]
    if "ipv6" in subnet:
        if "address" in subnet:
            data["network"]["ipv6_subnet"] = subnet["address"]
            data["network"]["ipv6_address"] = subnet["address"][:-3]
        if "gateway" in subnet:
            data["network"]["ipv6_gateway"] = subnet["gateway"]

json.dump(data, sys.stdout)
