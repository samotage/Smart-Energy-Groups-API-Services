
require 'rubygems'
require 'builder'
require "hem_adapter"
require "build_api_sites"
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


xml = BuildApiSites.make_put_xml(:site_token => "site_5a8b9b4ba4bb7adee7cec91450a4cdd099e5f208",
                                  :ext_stream_id => "stream_9948242",
                                  :device_serial_num => "switch_meter_002",
                                  :command_id => "1",
                                  :command_status => "Complete",
                                  :make_data => true,
                                  :date_time => Time.now,
                                  :number_points => 500)

puts xml

response = HemAdapter.send_command(:command => '/api_sites/site_5a8b9b4ba4bb7adee7cec91450a4cdd099e5f208.xml',
                                    :method => :put,
                                    :options => {"data_post" => xml },
                                    :host => "localhost",
                                    :port => 3000)

puts response


#site = HemAdapter.parse_response(:command => "api_sites",
#                                  :method => :get,
#                                  :xml_body => response)
#


