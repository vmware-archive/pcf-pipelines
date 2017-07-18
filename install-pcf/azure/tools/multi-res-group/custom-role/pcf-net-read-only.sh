#!/bin/bash
# Will need to set the subscription ID in the role json AssignableScopes
azure role create --inputfile pcf-net-read-only.json
#azure role set --inputfile pcf-net-read-only.json
