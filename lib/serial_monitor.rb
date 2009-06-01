#!/usr/local/bin/ruby

require 'rubygems'
require 'termios'
require "s_expression"


#
# This is a pretty basic piece of ugly hack code, designed for sunny day investigation.
# ...and it only works for temperature=
#
# The more robust client, taht works on multiple devices, feeds and units is hem_client,
# and controlled by main.rb.
#


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

while true do
  
  s_exp = cereal.gets

  if s_exp != nil &&  s_exp != ""
    puts s_exp
  end
end



