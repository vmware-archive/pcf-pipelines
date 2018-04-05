require 'yaml'

if ARGV.length != 1
  exit(1)
end

file = YAML.load_file(ARGV[0])

output = ''
file.each{ |k,v| output += "#{k}=\"#{v}\"\n"}

puts output
