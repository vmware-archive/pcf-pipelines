#!/usr/bin/env ruby
require 'tempfile'

def write_params(file, prefix, key, note_path)
  lpass_path = "Shared-PCF-NORM/#{note_path}"
  creds = `lpass show #{lpass_path}  --notes`

  if creds.to_s.strip.empty?
    puts "Could not fetch creds from #{lpass_path}"
    puts creds
    exit(1)
  end

  file.write("#{prefix}#{key}: |\n")

  creds.each_line do |line|
    file.write("  #{prefix}#{line}")
  end
end

fileName = 'pipeline_params'
tempfile = Tempfile.new(fileName)

prefix = ""
offline_prefix = "  "
write_params(tempfile, prefix,'rc_aws_install_params','rc/install-pcf/aws/pipeline.yml')
write_params(tempfile, prefix,'rc_gcp_install_params' ,'rc/install-pcf/gcp/pipeline.yml')
write_params(tempfile, prefix,'rc_azure_install_params' ,'rc/install-pcf/azure/pipeline.yml')
write_params(tempfile, prefix,'rc_vsphere_install_params' ,'rc/install-pcf/vsphere/pipeline.yml')
write_params(tempfile, offline_prefix, 'rc_offline_vsphere_install_params', 'offline/install-pcf/vsphere/pipeline.yml')
#write_params $tmpfile "" "create_offline_pinned_pipelines_params" 'create-offline-pinned-pipelines-params'
#write_params $tmpfile "" "unpack_pcf_pipelines_combined_params" 'unpack-pcf-pipelines-combined-params'
tempfile.write('  rc_offline_pipeline_name: rc-offline-vsphere-install')
tempfile.flush

flyCmd = "fly -t ci sp -p pcf-pipelines-master -c ci/pcf-pipelines/pipeline.yml \
  -l #{tempfile.path} \
  -l <(lpass show Shared-PCF-NORM/pcf-pipelines-params --notes) \
  -l <(lpass show Shared-PCF-NORM/pcf-norm-github --notes) \
  -l <(lpass show Shared-PCF-NORM/norm-pivnet --notes) \
  -l <(lpass show Shared-PCF-NORM/czero-mineo-lrpiec03 --notes)"

puts flyCmd

exec "bash -c '#{flyCmd}'"
#  -l <(lpass show czero-pivnet --notes)
#  -l <(lpass show minio-lrpiec03 --notes)
