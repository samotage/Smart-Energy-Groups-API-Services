#!/usr/local/bin/ruby

require 'rubygems'
require 'builder'
require 'termios'
require 'timeout'

require "hem_adapter"
require "build_api_sites"
require "hem_objects"
require "response_parser"
require "log_outputs"
require "s_expression"


#
# This is a pretty basic piece of ugly hack code, designed for sunny day investigation.
# ...and it only works for temperature=
#
# The more robust client, taht works on multiple devices, feeds and units is hem_client,
# and controlled by main.rb.
#

IO_SPEED = 115200
SERVER_TIMEOUT = 5 # seconds

#
#
## Sam's Home
site_token = "site_42121f21b26e7adf0dece67f356090b07167f93a"

# home temp
serial_num = "temp_001"
external_id = "temp_001"

## sam's shed temp
#device_serial = "temp_003"
#external_id = "temp_003"

## Sam's Office
#site_token = "site_3074eb0861efa6dca67c3d7334a297520c3d2201"
#device_serial = "temp_002"
#external_id = "temp_002"

# cereal = SerialPort.new "/dev/ttyUSB0", 115200

begin
  cereal = File.open("/dev/ttyUSB0")
rescue
  begin
    cereal = File.open("/dev/ttyUSB1")
  rescue
    cereal = File.open("/dev/ttyUSB2")
  end
end

tio = Termios.tcgetattr(cereal)
tio.ispeed = tio.ospeed = 115200
Termios.tcsetattr(cereal, Termios::TCSANOW, tio)

count = 1
data_logged = true
site = nil

while true do

  # Get the command to perform from HEM

  if data_logged == true
    begin
      Timeout::timeout(SERVER_TIMEOUT) do
        response = HemAdapter.send_command(
          :command => "/api_sites/#{site_token}.xml",
          :method => :get)

        site = ResponseParser.api_sites_xml(
          :command => "api_sites",
          :method => :get,
          :xml_body => response)

      end
    rescue Timeout::Error, Errno::ECONNREFUSED
      puts "...timeout in HEM Get command"
      false
    end
  end

  # Now listen on the serial port for something

  while true do
    result = nil
    s_exp = cereal.gets

    if s_exp != nil &&  s_exp != ""
      result = SExpression.parse(s_exp)

      # check what's been recieved for validity...

      if result != nil

        case result[0]
        when "temperature="
          break if result[1] != nil
        end
      end
    end
  end

  # Write some data into HEM.

  case result[0]
  when "temperature="
    puts "sending: #{result[0]} #{result[1]}"

    begin
      Timeout::timeout(SERVER_TIMEOUT) do

        xml = BuildApiSites.make_put_xml(
          :token => site_token,
          :device_serial_num => serial_num,
          :external_id => external_id,
          :date_time => Time.now,
          :value => result[1])

        response = HemAdapter.send_command(
          :command => "/api_sites/#{site_token}.xml",
          :method => :put,
          :options => {"data_post" => xml})

        data_logged = true

        puts "looped: #{count}"
        count += 1

      end
    rescue Timeout::Error, Errno::ECONNREFUSED
      puts "...timeout in HEM Put command"
      data_logged = false
      false
    end

  when "light="
    data_logged = false
  else
    data_logged = false
  end

  if site!= nil
    puts "sleeping now: #{site.poll_frequency} seconds"
    sleep(site.poll_frequency.to_i)
  else
    puts "there is something up with hem... & waiting #{SERVER_TIMEOUT} seconds"
    sleep(SERVER_TIMEOUT)
  end


end