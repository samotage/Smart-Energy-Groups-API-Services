#!/usr/local/bin/ruby

require 'rubygems'
require 'fcntl'
require 'termios'
require "s_expression"


#
# This is a pretty basic piece of ugly hack code, designed for sunny day investigation.
# ...and it only works for temperature=
#
# The more robust client, taht works on multiple devices, feeds and units is hem_client,
# and controlled by main.rb.

USB0 = '/dev/ttyUSB0'
USB1 = '/dev/ttyUSB1'
USB2 = '/dev/ttyUSB2'

BAUDRATE = Termios::B115200


def put_now?(count)
  return true if count.divmod(10000).last == 0
  return false
end



def dev_open(path)
  dev = open(path, File::RDWR | File::NONBLOCK)
  mode = dev.fcntl(Fcntl::F_GETFL, 0)
  dev.fcntl(Fcntl::F_SETFL, mode & ~File::NONBLOCK)
  return dev
end

def read_sexp(sexp)
  if sexp != nil &&  sexp != ""
    puts sexp
  end
end

begin
  cereal = dev_open(USB0)
rescue
  begin
    cereal = dev_open(USB1)
  rescue
    cereal = dev_open(USB2)
  end
end

# tio = Termios.tcgetattr(cereal)
# tio.ispeed = tio.ospeed = 115200
# Termios.tcsetattr(cereal, Termios::TCSANOW, tio)

count = 0
max_count = 10000000
toggle = false
command = "H"

while count < max_count do


  if put_now?(count)
    
    if toggle
      puts ""
      puts "--------------"
      puts "turning off"
      cereal.puts "L"
      toggle = false
    else
      puts ""
      puts "--------------"
      puts "turning on"
      cereal.puts("H")
      toggle = true
    end

    
  end

  sexp = cereal.gets
  read_sexp(sexp)

  sleep 0.001

  count += 1
end



