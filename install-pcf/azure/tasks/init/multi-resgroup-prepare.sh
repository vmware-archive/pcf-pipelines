#!/bin/bash

# Auth
azure login -u ${azure_multi_resgroup_subscription_owner_id} -p ${azure_multi_resgroup_subscription_owner_password} --tenant ${azure_tenant_id}


# Remove both Resource Groups
azure group delete --subscription ${azure_subscription_id} -n ${azure_multi_resgroup_pcf} -q
azure group delete --subscription ${azure_subscription_id} -n ${azure_multi_resgroup_network} -q

# Create Resgroup azure_multi_resgroup_network
azure group create ${azure_multi_resgroup_network} -l ${azure_region}
azure group deployment create -f pcf-pipelines/install-pcf/azure/tools/multi-res-group/arm/networking-resgroup/networking-resgroup.json -g ${azure_multi_resgroup_network}

# Create Resgroup azure_multi_resgroup_pcf
azure group create ${azure_multi_resgroup_pcf} -l ${azure_region}

## Assign Roles

azure role assignment create --spn ${azure_multi_resgroup_pcf_service_principal_spn} \
--roleName "PCF Network Read Only" --resource-group ${azure_multi_resgroup_network}

azure role assignment create --spn ${azure_multi_resgroup_pcf_service_principal_spn} \
--roleName "Contributor" --resource-group ${azure_multi_resgroup_pcf}
