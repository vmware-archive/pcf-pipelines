#!/bin/bash -e

gunzip ./govc/govc_linux_amd64.gz
chmod +x ./govc/govc_linux_amd64

govc=./govc/govc_linux_amd64
file_path=`find ./pivnet-opsman-product/ -name *.ova`

echo $file_path

$govc import.spec $file_path | python -m json.tool > om-import.json

cat > filters <<'EOF'
del(.Deployment) |
.Name = $vmName |
.DiskProvisioning = $diskType |
.NetworkMapping[].Network = $network |
.PowerOn = $powerOn |
(.PropertyMapping[] | select(.Key == "ip0")).Value = $ip0 |
(.PropertyMapping[] | select(.Key == "netmask0")).Value = $netmask0 |
(.PropertyMapping[] | select(.Key == "gateway")).Value = $gateway |
(.PropertyMapping[] | select(.Key == "DNS")).Value = $dns |
(.PropertyMapping[] | select(.Key == "ntp_servers")).Value = $ntpServers |
(.PropertyMapping[] | select(.Key == "admin_password")).Value = $adminPassword |
(.PropertyMapping[] | select(.Key == "custom_hostname")).Value = $customHostname
EOF

jq \
  --arg ip0 "$OM_IP" \
  --arg netmask0 "$OM_NETMASK" \
  --arg gateway "$OM_GATEWAY" \
  --arg dns "$OM_DNS_SERVERS" \
  --arg ntpServers "$OM_NTP_SERVERS" \
  --arg adminPassword "$OPS_MGR_SSH_PWD" \
  --arg customHostname "$OPS_MGR_HOST" \
  --arg network "$OM_VM_NETWORK" \
  --arg vmName "$OM_VM_NAME" \
  --arg diskType "$OM_DISK_TYPE" \
  --argjson powerOn $OM_VM_POWER_STATE \
  --from-file filters \
  om-import.json > options.json

cat options.json

$govc import.ova -options=options.json $file_path
