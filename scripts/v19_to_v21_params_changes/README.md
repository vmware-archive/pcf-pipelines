### Scripts to automate updating v19.2 to v21 install-pcf parameters

If you have existing install-pcf parameters, these scripts will help automate updating to new parameters names whilst keeping your environment variable values in tact.

### Usage

1. Navigate to this directory `v19_to_v21_params_changes`

1. In a command line, run `$ ./migrate_aws_install_pcf_params.sh LOCATION_OF_v19.2_PARAMETERS.yml > LOCATION_OF_v21_PARAMETERS.yml`

1. Ensure that for new params (ones which did not exist in v19.2), you add a value in your parameters file before setting the pipeline.
