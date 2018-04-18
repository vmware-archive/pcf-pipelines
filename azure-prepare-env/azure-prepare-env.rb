require yaml

def parseYaml(file)
  YAML.load_file(file)
end

# Pull variables from pipline yaml files
paramsFile = "params.yml"

params = {}
if File.file?(paramsFile)
  params = parseYaml(paramsFile)
else
  puts "params.yml does not exist! Exiting..."
  exit 1
end

# TODO check for file exists
eval $(ruby parse_yml.rb creds - template.yml)

IDENTIFIER_URI = "http://NETWORKAzureCPI-${azure_terraform_prefix}"
DISPLAY_NAME = "${azure_terraform_prefix}-Service Principal for NETWORK"

# ===============
# Resource Groups

az account set --subscription "${azure_subscription_id}"

NETWORK_RES_GROUP = $ (az group show --name "${azure_multi_resgroup_network}")

if [[-z
  "$NETWORK_RES_GROUP"]]; then
  echo "Creating resource group ${azure_multi_resgroup_network}"
  NETWORK_RES_GROUP = $ (
  az group create --name "${azure_multi_resgroup_network}" - -location "${azure_region}")
else
  echo "...Skipping resource group ${azure_multi_resgroup_network}.  Already exists."
  fi

  PCF_RES_GROUP = $ (
  az group show --name "${azure_multi_resgroup_pcf}")

  if [[-z
    "$PCF_RES_GROUP"]]; then
    echo "Creating resource group ${azure_multi_resgroup_pcf}"
    PCF_RES_GROUP = $ (
    az group create --name "${azure_multi_resgroup_pcf}" - -location "${azure_region}")
  else
    echo "...Skipping resource group ${azure_multi_resgroup_pcf}.  Already exists."
    fi


# ===============
# Create app and service principal for the Network resource group

# check for existing app by identifier-uri
    AZURE_NETWORK_SERVICE_PRINCIPAL_CLIENT_ID = $ (
    az ad app list \
      --identifier - uri "${IDENTIFIER_URI}" \
        | jq -r " .[] | .appId")

    if [[-z
      "$AZURE_NETWORK_SERVICE_PRINCIPAL_CLIENT_ID"]]; then
      echo "Creating client ${DISPLAY_NAME}"
      # create network application client
      AZURE_NETWORK_SERVICE_PRINCIPAL_CLIENT_ID = $ (
      az ad app create \
          --display - name "${DISPLAY_NAME}" \
            - -password "${azure_network_service_principal_client_secret}" \
            - -homepage "${IDENTIFIER_URI}" \
            - -identifier - uris "${IDENTIFIER_URI}" \
            | jq -r ".appId")
    else
      echo "...Skipping client ${DISPLAY_NAME}.  Already exists."
      fi

      SERVICE_PRINCIPAL_NAME = $ (
      az ad sp list --display - name "${DISPLAY_NAME}" | jq -r ".[] | .appId")

      if [[-z
        "$SERVICE_PRINCIPAL_NAME"]]; then
        echo "Creating service principal ${DISPLAY_NAME}"
        # create network service principal
        SERVICE_PRINCIPAL_NAME = $ (
        az ad sp create \
          --id ${AZURE_NETWORK_SERVICE_PRINCIPAL_CLIENT_ID} \
            | jq -r ".appId")
      else
        echo "...Skipping service principal ${DISPLAY_NAME}.  Already exists."
        fi

        ROLE_ID = $ (
        az role assignment list \
      --assignee ${SERVICE_PRINCIPAL_NAME} \
        - -role "Contributor" \
        - -scope /subscriptions/ ${azure_subscription_id} / resourceGroups / $ {azure_multi_resgroup_network} \
        | jq -r ".[] | .id")

        if [[-z
          "$ROLE_ID"]]; then

          echo "Applying Contributor access to ${DISPLAY_NAME} for resource group ${azure_multi_resgroup_network}"
          ROLE_ID = $ (
          az role assignment create \
          --assignee "${SERVICE_PRINCIPAL_NAME}" \
            - -role "Contributor" \
            - -scope /subscriptions/ ${azure_subscription_id} / resourceGroups / $ {azure_multi_resgroup_network} \
             | jq -r ".id")
        else
          echo "...Skipping Contributor roll assignment ${DISPLAY_NAME} for resource group ${azure_multi_resgroup_network}.  Already assigned."
          fi

          ROLE_ID = $ (
          az role assignment list \
      --assignee ${SERVICE_PRINCIPAL_NAME} \
        - -role "Contributor" \
        - -scope /subscriptions/ ${azure_subscription_id} / resourceGroups / $ {azure_multi_resgroup_pcf} \
        | jq -r ".[] | .id")

          if [[-z
            "$ROLE_ID"]]; then

            echo "Applying Contributor access to ${DISPLAY_NAME} for resource group ${azure_multi_resgroup_pcf}"
            ROLE_ID = $ (
            az role assignment create \
          --assignee "${SERVICE_PRINCIPAL_NAME}" \
            - -role "Contributor" \
            - -scope /subscriptions/ ${azure_subscription_id} / resourceGroups / $ {azure_multi_resgroup_pcf} \
             | jq -r ".id")
          else
            echo "...Skipping Contributor roll assignment ${DISPLAY_NAME} for resource group ${azure_multi_resgroup_pcf}.  Already assigned."
            fi


# ===============
# Create app and service principal for the BOSH/PCF resource group

            BOSH_IDENTIFIER_URI = "http://BOSHAzureCPI-${azure_terraform_prefix}"
            BOSH_DISPLAY_NAME = "${azure_terraform_prefix}-Service Principal for BOSH"

# check for existing app by identifier-uri
            AZURE_PCF_SERVICE_PRINCIPAL_CLIENT_ID = $ (
            az ad app list \
      --identifier - uri "${BOSH_IDENTIFIER_URI}" \
        | jq -r " .[] | .appId")

            if [[-z
              "$AZURE_PCF_SERVICE_PRINCIPAL_CLIENT_ID"]]; then
              echo "Creating client ${BOSH_DISPLAY_NAME}"
              # create BOSH application client
              AZURE_PCF_SERVICE_PRINCIPAL_CLIENT_ID = $ (
              az ad app create \
          --display - name "${BOSH_DISPLAY_NAME}" \
            - -password "${azure_pcf_service_principal_client_secret}" \
            - -homepage "${BOSH_IDENTIFIER_URI}" \
            - -identifier - uris "${BOSH_IDENTIFIER_URI}" \
            | jq -r ".appId")
            else
              echo "...Skipping client ${BOSH_DISPLAY_NAME}.  Already exists."
              fi

              SERVICE_PRINCIPAL_NAME = $ (
              az ad sp list --display - name "${BOSH_DISPLAY_NAME}" | jq -r ".[] | .appId")

              if [[-z
                "$SERVICE_PRINCIPAL_NAME"]]; then
                echo "Creating service principal ${BOSH_DISPLAY_NAME}"
                # create BOSH service principal
                SERVICE_PRINCIPAL_NAME = $ (
                az ad sp create \
          --id ${AZURE_PCF_SERVICE_PRINCIPAL_CLIENT_ID} \
            | jq -r ".appId")
              else
                echo "...Skipping service principal ${BOSH_DISPLAY_NAME}.  Already exists."
                fi

#TODO service principal creation completes asynchronously.  Need to wait for completion before continuing.

                ROLE_ASSIGNMENT_CONTRIBUTOR = $ (
                az role assignment list \
      --role "Contributor" \
        - -assignee ${AZURE_PCF_SERVICE_PRINCIPAL_CLIENT_ID} \
        - -scope "/subscriptions/${azure_subscription_id}/resourceGroups/${azure_multi_resgroup_pcf}" | jq -r ".[0]")

                if [[-z
                  "${ROLE_ASSIGNMENT_CONTRIBUTOR/null/}"]]; then
                  echo "Assigning Contributor role for resource group ${azure_multi_resgroup_pcf} to BOSH/PCF service principal"
                  ROLE_ASSIGNMENT_CONTRIBUTOR = $ (
                  az role assignment create \
          --role "Contributor" \
            - -assignee ${AZURE_PCF_SERVICE_PRINCIPAL_CLIENT_ID} \
            - -scope "/subscriptions/${azure_subscription_id}/resourceGroups/${azure_multi_resgroup_pcf}")
                else
                  echo "...Skipping assignment of Contributor role for resource group ${azure_multi_resgroup_pcf}.  Already assigned."
                  fi


# create custom roles
                  ROLE_NETWORK_READONLY_NAME = "PCF Network Read Only (custom) norm-rc-multi-res"
                  ROLE_NETWORK_READONLY_JSON = $ (jq -n --arg azure_subscription_id "/subscriptions/${azure_subscription_id}" \
    '
    {
      "Name": "PCF Network Read Only (custom) norm-rc-multi-res",
      "IsCustom": true,
      "Description": "PCF Read Network Resource Group (custom) for norm-rc-multi-res",
      "Actions": [
        "Microsoft.Network/networkSecurityGroups/read",
        "Microsoft.Network/networkSecurityGroups/join/action",
        "Microsoft.Network/publicIPAddresses/read",
        "Microsoft.Network/publicIPAddresses/join/action",
        "Microsoft.Network/loadBalancers/read",
        "Microsoft.Network/virtualNetworks/subnets/read",
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/read"
      ],
      "NotActions": [],
      "AssignableScopes": [$azure_subscription_id]
    }
    ')


                  ROLE_NETWORK_READ_ONLY = $ (
                  az role definition list \
      --custom - role - only true \
        - -name "${ROLE_NETWORK_READONLY_NAME}" \
        - -scope "/subscriptions/${azure_subscription_id}" | jq -r ".[0]")

                  if [[-z
                    "${ROLE_NETWORK_READ_ONLY/null/}"]]; then
                    echo "Creating custom role ${ROLE_NETWORK_READONLY_NAME}"
                    ROLE_NETWORK_READ_ONLY = $ (
                    az role definition create \
            --role - definition "${ROLE_NETWORK_READONLY_JSON}")
                  else
                    echo "...Skipping custom role ${ROLE_NETWORK_READONLY_NAME}.  Already exists."
                    fi

                    ROLE_ASSIGNMENT_NETWORK = $ (
                    az role assignment list \
      --role "${ROLE_NETWORK_READONLY_NAME}" \
        - -assignee ${AZURE_PCF_SERVICE_PRINCIPAL_CLIENT_ID} \
        - -scope "/subscriptions/${azure_subscription_id}/resourceGroups/${azure_multi_resgroup_network}" | jq -r ".[0]")

                    if [[-z
                      "${ROLE_ASSIGNMENT_NETWORK/null/}"]]; then
                      echo "Assigning custom role ${ROLE_NETWORK_READONLY_NAME} to BOSH/PCF service principal"
                      ROLE_ASSIGNMENT_NETWORK = $ (
                      az role assignment create \
          --role "${ROLE_NETWORK_READONLY_NAME}" \
            - -assignee ${AZURE_PCF_SERVICE_PRINCIPAL_CLIENT_ID} \
            - -scope "/subscriptions/${azure_subscription_id}/resourceGroups/${azure_multi_resgroup_network}")
                    else
                      echo "...Skipping assignment of custom role ${ROLE_NETWORK_READONLY_NAME}.  Already assigned."
                      fi

                      ROLE_PCF_DEPLOY_NAME = "PCF Deploy Min Perms (custom) norm-rc-multi-res"
                      ROLE_PCF_DEPLOY_JSON = $ (jq -n --arg azure_subscription_id "/subscriptions/${azure_subscription_id}" \
    '
    {
      "Name": "PCF Deploy Min Perms (custom) norm-rc-multi-res",
      "IsCustom": true,
      "Description": "PCF Terraform Perms (custom) for norm-rc-multi-res",
      "Actions": [
        "Microsoft.Compute/register/action"
      ],
      "NotActions": [],
      "AssignableScopes": [$azure_subscription_id]
    }
    ')

                      ROLE_PCF_DEPLOY_ONLY = $ (
                      az role definition list \
      --custom - role - only true \
        - -name "${ROLE_PCF_DEPLOY_NAME}" \
        - -scope "/subscriptions/${azure_subscription_id}" | jq -r ".[0]")


                      if [[-z
                        "${ROLE_PCF_DEPLOY_ONLY/null/}"]]; then
                        echo "Creating custom role ${ROLE_PCF_DEPLOY_NAME}"
                        ROLE_PCF_DEPLOY_ONLY = $ (
                        az role definition create \
            --role - definition "${ROLE_PCF_DEPLOY_JSON}")
                      else
                        echo "...Skipping custom role ${ROLE_PCF_DEPLOY_NAME}.  Already exists."
                        fi

                        ROLE_ASSIGNMENT_PCF_DEPLOY = $ (
                        az role assignment list \
      --role "${ROLE_PCF_DEPLOY_NAME}" \
        - -assignee ${AZURE_PCF_SERVICE_PRINCIPAL_CLIENT_ID} \
        - -scope "/subscriptions/${azure_subscription_id}/resourceGroups/${azure_multi_resgroup_network}" | jq -r ".[0]")

                        if [[-z
                          "${ROLE_ASSIGNMENT_PCF_DEPLOY/null/}"]]; then
                          echo "Assigning custom role ${ROLE_PCF_DEPLOY_NAME} to BOSH/PCF service principal"
                          ROLE_ASSIGNMENT_PCF_DEPLOY = $ (
                          az role assignment create \
          --role "${ROLE_PCF_DEPLOY_NAME}" \
            - -assignee ${AZURE_PCF_SERVICE_PRINCIPAL_CLIENT_ID} \
            - -scope "/subscriptions/${azure_subscription_id}/resourceGroups/${azure_multi_resgroup_network}")
                        else
                          echo "...Skipping assignment of custom role ${ROLE_PCF_DEPLOY_NAME}.  Already assigned."
                          fi


# create storage account for infra terraform pipeline
                          STORAGE_ACCOUNT = $ (
                          az storage account list \
      --resource - group "${azure_multi_resgroup_pcf}" \
        | jq -r ".[] | select(.name == \"${azure_pcf_terraform_storage_account_name}\")")

                          if [[-z
                            "${STORAGE_ACCOUNT/null/}"]]; then
                            echo "Creating storage account ${azure_pcf_terraform_storage_account_name}"
                            STORAGE_ACCOUNT = $ (
                            az storage account create \
          --name "${azure_pcf_terraform_storage_account_name}" \
            - -resource - group "${azure_multi_resgroup_pcf}" \
            - -sku "Standard_LRS")
                          else
                            echo "...Skipping storage account ${azure_pcf_terraform_storage_account_name}.  Already exists."
                            fi

                            STORAGE_CONTAINER = $ (
                            az storage container show \
      --name "${azure_pcf_terraform_container_name}" \
        - -account - name "${azure_pcf_terraform_storage_account_name}")

                            if [[-z
                              "${STORAGE_CONTAINER/null/}"]]; then
                              echo "Creating storage container ${azure_pcf_terraform_container_name}"
                              STORAGE_CONTAINER = $ (
                              az storage container create \
          --name "${azure_pcf_terraform_container_name}" \
            - -account - name = "${azure_pcf_terraform_storage_account_name}")
                            else
                              echo "...Skipping storage container ${azure_pcf_terraform_container_name}.  Already exists."
                              fi

                              echo
                              echo "Populate params.yml with these values:"
                              echo
                              echo "azure_network_service_principal_client_id: ${AZURE_NETWORK_SERVICE_PRINCIPAL_CLIENT_ID}"
                              echo "azure_multi_resgroup_network_client_id: ${AZURE_PCF_SERVICE_PRINCIPAL_CLIENT_ID}"

