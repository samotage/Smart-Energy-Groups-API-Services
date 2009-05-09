
require 'rubygems'
require 'builder'
require "hem_adapter"
require "build_api_sites"
require "hem_objects"
require "response_parser"
require "log_outputs"

# README
#
# This program doesn't represent any actual usefulness for your projects apart from demonstrating the
# useage of the various functions within the HEM adaptor.
#
# So test away as you please, and you can incorporate these method calls within your ruby project.
#
# Note you WILL need to get your site key, available within HEM when you edit your site.
#
##################
#
#  Important, have a gander at:
#  
#   api_sites_put_example.rb
#   api_sites_get_example.rb
#
#   for a working example to fiddle about with
#
##################


# The following has a token for my site, so please be careful - and it is subject to change ;)

response = HemAdapter.send_command(
  :command => '/api_sites/site_42121f21b26e7adf0dece67f356090b07167f93a.xml',
  :method => :get)


site = ResponseParser.api_sites(
  :command => "api_sites",
  :method => :get,
  :xml_body => response)

if site != nil
  LogOutputs.site_to_screen(site)
else
  puts "got nothing back from Hem"
end



