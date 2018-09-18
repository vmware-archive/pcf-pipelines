#!/usr/bin/env ruby

require 'tempfile'
require 'fileutils'
require 'yaml'


def load_param(note_path)
  File.read(File.expand_path("~/workspace/secrets/#{note_path}"))
end

params = {}
params['rc_aws_install_params'] = load_param('rc/install-pcf/aws/pipeline.yml')
params['rc_gcp_install_params'] = load_param('rc/install-pcf/gcp/pipeline.yml')
params['rc_azure_install_params'] = load_param('rc/install-pcf/azure/pipeline.yml')
params['rc_vsphere_install_params'] = load_param('rc/install-pcf/vsphere/pipeline.yml')
params['rc_lre_gcp_upgrade_ops_manager_params'] = load_param('lre/upgrade-ops-manager/gcp/pipeline.yml')
params['rc_gcp_upgrade_pas_tile_params'] = load_param('rc/upgrade-pas-tile/gcp/pipeline.yml')
params['create_offline_pinned_pipelines_params'] = load_param('create-offline-pinned-pipelines/pipeline.yml')
params['rc_offline_pipeline_name'] = 'rc-offline-vsphere-install'
params['unpack_pcf_pipelines_combined_params'] = {
    'rc_offline_vsphere_install_params' => load_param('offline/install-pcf/vsphere/pipeline.yml'),
    'rc_offline_pipeline_name' => params['rc_offline_pipeline_name'],

}.merge(YAML.load(load_param('unpack-pcf-pipelines-combined-params'))).to_yaml

file = Tempfile.new('pipeline_params')
file.write(params.to_yaml)
file.close

fly_cmd = "fly -t #{ENV.fetch('FLY_TARGET')} sp -p pcf-pipelines-master -c ci/pcf-pipelines/pipeline.yml \
  -l #{file.path} \
  -l ~/workspace/secrets/pcf-pipelines-params \
  -l ~/workspace/platform-automation-deployments/platform-automation/ci/github-secrets \
  -l ~/workspace/secrets/pcf-pipelines-pivnet"

puts fly_cmd
system(fly_cmd)