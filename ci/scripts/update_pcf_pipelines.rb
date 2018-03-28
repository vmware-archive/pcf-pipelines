#!/usr/bin/env ruby

require 'tempfile'
require 'yaml'

@params = {}
def load_params(key, note_path)
  lpass_path = "Shared-PCF-NORM/#{note_path}"
  creds = `lpass show #{lpass_path}  --notes`.chomp

  if creds.empty?
    puts "Could not fetch creds from #{lpass_path}"
    puts creds
    exit(1)
  end

  @params[key] = creds
end




load_params('rc_aws_install_params','rc/install-pcf/aws/pipeline.yml')
load_params('rc_gcp_install_params' ,'rc/install-pcf/gcp/pipeline.yml')
load_params('rc_azure_install_params' ,'rc/install-pcf/azure/pipeline.yml')
load_params('rc_vsphere_install_params' ,'rc/install-pcf/vsphere/pipeline.yml')
load_params('rc_lre_gcp_upgrade_ops_manager_params' ,'lre/upgrade-ops-manager/gcp/pipeline.yml')
load_params('rc_gcp_upgrade_pas_tile_params', 'rc/upgrade-pas-tile/gcp/pipeline.yml')
# write_params( 'rc_offline_vsphere_install_params', 'offline/install-pcf/vsphere/pipeline.yml')
# tempfile.write('  rc_offline_pipeline_name: rc-offline-vsphere-install')

file = Tempfile.new('pipeline_params')
file.write(@params.to_yaml)
file.close

flyCmd = "fly -t ci sp -p pcf-pipelines-master -c ci/pcf-pipelines/pipeline.yml \
  -l #{file.path} \
  -l <(lpass show Shared-PCF-NORM/pcf-pipelines-params --notes) \
  -l <(lpass show Shared-PCF-NORM/pcf-norm-github --notes) \
  -l <(lpass show Shared-PCF-NORM/norm-pivnet --notes) \
  -l <(lpass show Shared-PCF-NORM/czero-mineo-lrpiec03 --notes)"

puts flyCmd

exec "bash -c '#{flyCmd}'"
