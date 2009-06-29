
require 'rubygems'
require "hem_adapter"
require "build_api_streams"
require "hem_objects"

# README
#
# This program doesn't represent any actual usefulness for your projects apart from demonstrating the
# useage of the various functions within the HEM adaptor.
#
# So test away as you please, and you can incorporate these method calls within your ruby project.
#

seed_dt = Time.mktime( 2009, 3, 01, 00, 00, 00)

xml = BuildApiStreams.make_stream_xml(
  :external_id => "switch_002",
  :make_data => true,
  :number_points => 1)

puts xml

#A local example, note the host and port

result = HemAdapter.send_command(
  :command => '/api_streams/switch_002.xml',
  :method => :put,
  :options => {"data_post" => xml },
  :host => "localhost",
  :port => 3000)


# A remote example, defaults to api.smartenergygroups.com on port 80

#site = HemAdapter.send_command(
#  :command => '/api_sites/site_5a8b9b4ba4bb7adee7cec91450a4cdd099e5f208.xml',
#  :method => :put,
#  :options => {"data_post" => xml })

puts result


