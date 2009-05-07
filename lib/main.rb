
require 'rubygems'
require 'builder'
require "hem_adapter"
require "build_stream"
require "build_ask_hem"
require "hem_objects"

# README
#
# This program doesn't represent any actual usefulness for your projects apart from demonstrating the
# useage of the various functions within the HEM adaptor.
#
# So test away as you please, and you can incorporate these method calls within your ruby project.
#
# Note you WILL need to get your site key, available within HEM when you edit your site.
#



# The following has a token for my site, so please be careful - and it is subject to change ;)

response = HemAdapter.send_command(:command => '/api_sites/f7444ad62e7a7d9c6beb9c2f3a0455dff8c61f6a.xml',
                                    :method => :get)


site = HemAdapter.parse_response(:command => "api_sites",
                                  :method => :get,
                                  :xml_body => response)
puts site

puts site.site_token 
puts site.last_ip_address
puts site.poll_frequency
puts site.poll_scatter

site.devices.each do |device|

  puts   ".new.device." + device.serial
  puts   "............" + device.device_resource
  puts   "............" + device.name
  puts   "............" + device.type

  device.commands.each do |command|
    puts   ".new_commad./...command..." + command.command_id
    puts   "............/...command..." + command.command_resource
    puts   "............/...command..." + command.comand_type
    puts   "............/...command..." + command.status
    puts   "............/...command..." + command.execute_at
    puts   "............/...command..." + command.executed_at
    puts   "............/...command..." + command.priority
    puts   "............/...command..." + command.confirm_type
  end

  device.streams.each do |stream|
    puts   ".new.stream./...stream..." + stream.ext_stream_id
    puts   "............/...stream..." + stream.stream_resource
    puts   "............/...stream..." + stream.updated_at
    puts   "............/...stream..." + stream.stream_type
    puts   "............/...stream..." + stream.unit_type
  end
end

