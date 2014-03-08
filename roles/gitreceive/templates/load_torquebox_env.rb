require 'yaml'

config = YAML.load_file(File.expand_path("../../torquebox/production-knob.yml",  __FILE__))

config['environment'].each do |k,v|
  ENV[k] = v
end

p "---- This is the current environment -----"
ENV.each do |k,v|
  p "------ #{k} = #{v}"
end