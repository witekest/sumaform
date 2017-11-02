#!/usr/bin/env ruby
# encoding: UTF-8

require 'optparse'

key_file = ""
mirror_public_name = ""
single_instances = []
multiple_instances = []
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on("-k", "--key-file [KEY_FILE]", "key file path") do |ext|
    key_file = ext
  end

  opts.on("-m", "--mirror [MIRROR_PUBLIC_NAME]", "mirror's public name") do |ext|
    mirror_public_name = ext
  end

  opts.on("-s", "--single-instance [SYMBOLIC_NAME:PRIVATE_NAME]", "symbolic name to private AWS name association for a single instance") do |ext|
    single_instances << { symbolic_name: ext.split(":")[0], private_name: ext.split(":")[1] }
  end

  opts.on("-p", "--multiple-instance [SYMBOLIC_NAME:PRIVATE_NAME,PRIVATE_NAME,...]", "symbolic name to private AWS name association for multiple instances") do |ext|
    base_symbolic_name = ext.split(":")[0]
    multiple_instances += ext.split(":")[1].split(",").each_with_index.map do |name, index|
      { symbolic_name: "#{base_symbolic_name}-#{index}", private_name: name }
    end.flatten
  end
end.parse!

instances = single_instances + multiple_instances

tunnel_string = <<-eos
# sumaform configuration start
Host mirror
  HostName #{mirror_public_name}
  StrictHostKeyChecking no
  User root
  IdentityFile #{key_file}
  ServerAliveInterval 120
eos

instances.each do |instance|
  tunnel_string += <<-eos

  Host #{instance[:symbolic_name]}
    HostName #{instance[:private_name]}
    StrictHostKeyChecking no
    User root
    IdentityFile #{key_file}
    ProxyCommand ssh root@mirror -W %h:%p
    ServerAliveInterval 120
  eos
  if instance[:symbolic_name] =~ /suma/
    tunnel_string += "    LocalForward 8043 127.0.0.1:443\n"
  end
  if instance[:symbolic_name] =~ /grafana/
    tunnel_string += "    LocalForward 8080 127.0.0.1:80\n"
    tunnel_string += "    LocalForward 9090 127.0.0.1:9090\n"
  end
end

tunnel_string += "# sumaform configuration end"

config_path = "#{Dir.home}/.ssh/config"
config_string = File.read(config_path)

if config_string =~ /(.*)^# sumaform configuration start$(.*)^# sumaform configuration end$(.*)/m
  File.write(config_path, "#{$1}#{tunnel_string}#{$3}")
else
  File.write(config_path, "#{config_string}\n#{tunnel_string}\n")
end
