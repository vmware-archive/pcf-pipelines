## Known Issues:

- The upgrade-ops-manager pipeline for Azure does not work for Canada Central. It does work on Canada East.
- The Ops Manager vm name automatically changes each time you run the pipeline. If you are using the upgrade-ops-manager pipeline more than once, you will need to update `existing_opsman_vm_name` each time you run the pipeline. 
