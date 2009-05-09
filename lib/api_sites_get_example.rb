
require 'rubygems'
require 'builder'
require "hem_adapter"
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



# The following has a token for my site, so please be careful - and it is subject to change ;)

response = HemAdapter.send_command(:command => '/api_sites/site_5a8b9b4ba4bb7adee7cec91450a4cdd099e5f208.xml',
                                    :method => :get,
                                    :host => "localhost",
                                    :port => 3000)


site = ResponseParser.api_sites(:command => "api_sites",
                                  :method => :get,
                                  :xml_body => response)

if site != nil
  LogOutputs.site_to_screen(site)
else
  puts "nothing back from Hem"
end



