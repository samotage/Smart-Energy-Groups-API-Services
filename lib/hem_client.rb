require 'rubygems'
require 'builder'
require "hem_adapter"
require "build_api_sites"
require "hem_objects"
require "response_parser"
require "log_outputs"
require "s_expression"
require 'termios'

site_token = "site_42121f21b26e7adf0dece67f356090b07167f93a"
# cereal = SerialPort.new "/dev/ttyUSB0", 115200

cereal = File.open("/dev/ttyUSB0")

tio = Termios.tcgetattr(cereal)
tio.ispeed = tio.ospeed = 115200
Termios.tcsetattr(cereal, Termios::TCSANOW, tio)

count = 1
data_logged = true

while true do

  # Get the command to perform from HEM

  if data_logged == true

    response = HemAdapter.send_command(
      :command => "/api_sites/#{site_token}.xml",
      :method => :get)

    site = ResponseParser.api_sites(
      :command => "api_sites",
      :method => :get,
      :xml_body => response)
  end

  # Now listen on the serial port for something

  while true do
    s_exp = cereal.gets

    if s_exp != nil &&  s_exp != ""
      result = SExpression.parse(s_exp)
      break
    end
  end

  # Write some data into HEM.

  case result[0]
  when "temperature="
    xml = BuildApiSites.make_put_xml(
      :site_token => site_token,
      :device_serial_num => "temp_001",
      :ext_stream_id => "temp_001",
      :date_time => Time.now,
      :value => result[1])

    response = HemAdapter.send_command(
      :command => "/api_sites/#{site_token}.xml",
      :method => :put,
      :options => {"data_post" => xml})

    data_logged = true

    puts "looped: #{count}"
    count += 1

    puts "sleeping now: #{site.poll_frequency} seconds"
    sleep(site.poll_frequency.to_i)

  when "light="
    data_logged = false
  else
    data_logged = false
  end
end

