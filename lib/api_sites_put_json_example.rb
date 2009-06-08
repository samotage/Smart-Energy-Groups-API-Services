

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

#This has single hash streams
json_string = %|{"site":{"devices":{"device":[{"name":"Heater Monitor","serial_num":"HEATER-001","index_seq":null,"device_resource":"http:\/\/localhost:3000\/api_devices\/HEATER-001.xml","type":"Switch Thermometer","streams":{"stream":{"sequence":"1","stream_resource":"http:\/\/localhost:3000\/api_streams\/.xml","unit_type":"C","updated_at":"2009-05-02 06:05:01 UTC","stream_type":"Temperature","external_id":null}},"commands":null},{"name":"Aux Circuit Control","serial_num":"switch_meter_002","index_seq":null,"device_resource":"http:\/\/localhost:3000\/api_devices\/switch_meter_002.xml","type":"Switch Meter","streams":{"stream":{"sequence":"1","stream_resource":"http:\/\/localhost:3000\/api_streams\/stream_9948242.xml","unit_type":"kWh","updated_at":"2009-05-03 06:29:41 UTC","stream_type":"Energy Consumption","external_id":"stream_9948242"}},"commands":{"command":{"confirm_type":"Immediate","executed_at":null,"priority":null,"command_resource":"http:\/\/localhost:3000\/api_commands\/1.xml","command_type":"switch_off","command_id":"1","execute_at":"2009-05-09 06:03:44 UTC","status":"Pending"}}}]},"name":"Json Integration Site","token":"site_5a8b9b4ba4bb7adee7cec91450a4cdd099e5f208","last_ip_address":"127.0.0.1","poll_frequency":"360","site_resource":"http:\/\/localhost:3000\/api_sites\/site_5a8b9b4ba4bb7adee7cec91450a4cdd099e5f208.xml","type":"Factory","poll_scatter":null}}|

#This has an array of streams
json_string = %|{"site":{"devices":{"device":[{"name":"un-named","serial_num":"METER-0001","index_seq":null,"device_resource":"http:\/\/localhost:3000\/api_devices\/METER-0001.xml","type":"Energy Meter","streams":{"stream":{"sequence":"1","stream_resource":"http:\/\/localhost:3000\/api_streams\/sge_test_stream.xml","unit_type":"Wh","updated_at":"2009-05-06 01:16:37 UTC","stream_type":"Energy Consumption","external_id":"sge_test_stream"}},"commands":null},{"name":"TestType 4","serial_num":"type4 meterey","index_seq":null,"device_resource":"http:\/\/localhost:3000\/api_devices\/type4 meterey.xml","type":"Type 4 Interval Meter","streams":{"stream":[{"sequence":"1","stream_resource":"http:\/\/localhost:3000\/api_streams\/.xml","unit_type":"kWh","updated_at":"2009-05-10 05:28:56 UTC","stream_type":"Energy Consumption","external_id":null},{"sequence":"1","stream_resource":"http:\/\/localhost:3000\/api_streams\/.xml","unit_type":"kVA","updated_at":"2009-05-10 05:28:56 UTC","stream_type":"Demand kVA","external_id":null},{"sequence":"1","stream_resource":"http:\/\/localhost:3000\/api_streams\/.xml","unit_type":"pf","updated_at":"2009-05-10 05:28:56 UTC","stream_type":"Power Factor","external_id":null},{"sequence":"1","stream_resource":"http:\/\/localhost:3000\/api_streams\/.xml","unit_type":"C","updated_at":"2009-05-10 05:28:56 UTC","stream_type":"Temperature","external_id":null}]},"commands":null}]},"name":"Test Data","token":"1b5adf6565afbf4736cc5409ebbcfb28c2681140","last_ip_address":"127.0.0.1","poll_frequency":"360","site_resource":"http:\/\/localhost:3000\/api_sites\/1b5adf6565afbf4736cc5409ebbcfb28c2681140.xml","type":"Factory","poll_scatter":null}}|

#this has a single device, 3 points
json_string = %|{"site":{"devices":{"device":{"name":"Switch Meter","serial_num":"SWMET01","index_seq":null,"device_resource":"http:\/\/localhost:3000\/api_devices\/SWMET01.xml","type":"Switch Meter","streams":{"stream":{"sequence":"10","stream_resource":"http:\/\/localhost:3000\/api_streams\/Extey5.xml","unit_type":"kWh","updated_at":"2009-05-09 05:52:28 UTC","points":{"point":[{"value":"110.0","point_date":"2009-05-10 17:06:36"},{"value":"194.147","point_date":"2009-05-10 17:36:36"},{"value":"200.93","point_date":"2009-05-10 18:06:36"}]},"stream_type":"Energy Consumption","external_id":"Extey5"}},"commands":null}},"name":"Sam's Family Home","token":"site_a8db2cfd72fc45f6b5910314a703c42969b1f5e6","last_ip_address":"127.0.0.1","poll_frequency":"360","site_resource":"http:\/\/localhost:3000\/api_sites\/site_a8db2cfd72fc45f6b5910314a703c42969b1f5e6.xml","type":"Home","poll_scatter":null}}|

#this has a single device, 1 point
json_string = %|{"site":{"devices":{"device":{"name":"Switch Meter","serial_num":"SWMET01","index_seq":null,"device_resource":"http:\/\/localhost:3000\/api_devices\/SWMET01.xml","type":"Switch Meter","streams":{"stream":{"sequence":"10","stream_resource":"http:\/\/localhost:3000\/api_streams\/Extey5.xml","unit_type":"kWh","updated_at":"2009-05-09 05:52:28 UTC","points":{"point":{"value":"110.0","point_date":"2009-05-10 17:06:36"}},"stream_type":"Energy Consumption","external_id":"Extey5"}},"commands":null}},"name":"Sam's Family Home","token":"site_a8db2cfd72fc45f6b5910314a703c42969b1f5e6","last_ip_address":"127.0.0.1","poll_frequency":"360","site_resource":"http:\/\/localhost:3000\/api_sites\/site_a8db2cfd72fc45f6b5910314a703c42969b1f5e6.xml","type":"Home","poll_scatter":null}}|


json_string = %|
{
  "site":
  {
    "name":"Sam's Family Home",
    "token":"site_a8db2cfd72fc45f6b5910314a703c42969b1f5e6",
    "devices":
    {
      "device":
      { "name":"Switch Meter",
          "serial_num":"SWMET01",
          "index_seq":null,
          "streams":
          {
            "stream":
            {
              "external_id":"Extey5",
              "sequence":"10",
              "points":
              {
                "point":[
                          {"value":"36.45","point_date":"2008-12-08 00:00:00"},
                          {"value":"34.74","point_date":"2008-12-08 00:30:00"},
                          {"value":"34.52","point_date":"2008-12-08 01:00:00"},
                          {"value":"34.57","point_date":"2008-12-08 01:30:00"}
                        ]
              }
            }
          },
          "commands":
          {
            "command":
            {
              "command_id":"37",
              "status":"Complete",
              "executed_at":"2009-05-11 02:26:55"
            }
          }
       }
    }
  }
}
|


#A local example, note the host and port

site = HemAdapter.send_command(
  :command => '/api_sites/site_a8db2cfd72fc45f6b5910314a703c42969b1f5e6.json',
  :method => :put,
  :options => {"data_post" => json_string })

#
## A remote example, defaults to api.smartenergygroups.com on port 80
#
#site = HemAdapter.send_command(
#  :command => '/api_sites/site_5a8b9b4ba4bb7adee7cec91450a4cdd099e5f208.xml',
#  :method => :put,
#  :options => {"data_post" => xml })
#


puts site



