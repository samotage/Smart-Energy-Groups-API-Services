#!/usr/local/bin/ruby

require 'rubygems'
require 'builder'
require 'timeout'

require "hem_adapter"
require "build_api_sites"

require "obj_site"
require "obj_device"
require "obj_command"
require "obj_stream"
require "obj_stream_point"

require "usb_serial"

require "response_parser"
require "log_outputs"


IS_PROD = false

MAIN_LOOP_COUNT = 20

HEM_COUNT = 10
HEM_WAIT = 3

STREAM_TRY = 3
STRAM_WAIT = 1

COMMAND_TRY = 3
COMMAND_WAIT = 1

ON = "(relay= on)"
OFF = "(relay= off)"

DEFAULT_SITE_TOKEN = "site_42121f21b26e7adf0dece67f356090b07167f93a"

module HemClient

  class HemClient::Client
    attr_accessor :serial_connections

    attr_accessor :site_token
    attr_accessor :site
    
    def initialize
      @site_token = DEFAULT_SITE_TOKEN
      @serial_connections = nil

      @site = ObjSite::Site.new
      
      puts "" if !QUIET
      puts "###########################################################################" if !QUIET
      puts "---Establishing Client-----------------------------------------" if !QUIET
      puts "---Environment is: Production" if IS_PROD
      puts "---Environment is: Development" if !IS_PROD
    end

    def run_loop
      count = 0
      heart_beating = false
      self.site = ObjSite::Site.get_site(self.site_token)

      while count < MAIN_LOOP_COUNT do
        #loop flags...
        synch_ok = false
        got_data = false
        commands_ok = false
        put_site = false
        connections_assigned = false

        puts "  " if !QUIET
        puts "-------this is a new loop #{count}---------------------------------" if !QUIET
        if self.site != nil

          self.serial_connections = UsbSerial::Connections.establish_serial_connections
          beating = self.serial_connections.check_all_beating
          if !self.serial_connections
            return nil
          end
          connections_assigned = self.site.assign_connections(self.serial_connections)

          # Do the stuff, first up synch!
          synch_ok = self.site.synch_energisation
          puts "-------Synch failed" if !QUIET && WHINY && !synch_ok


          got_data = self.site.acquire_data

          # commands_ok = self.site.execute_commands

          if !QUIET && WHINY && commands_ok
            puts "  "
            puts "-------Executed Commands #{count}---------------------------------"
          end

          if !QUIET && WHINY && got_data && commands_ok
            puts "Nothing to do on loop: #{count}"
          end

          self.site = self.site.put_site
          if self.site
            puts "Acquired data sent to HEM" if !QUIET && WHINY
          else
            puts "Something failed sending acquired data to HEM" if !QUIET
          end
          count += 1
          puts "loop counter: #{count}" if !QUIET && WHINY
          puts "sleeping now: #{self.site.poll_frequency} seconds" if !QUIET && WHINY
          sleep(self.site.poll_frequency.to_i)
        end
      end
      return count
    end

    def establish_serial_connections
      establish_ok = false

      self.serial_connections = nil
      self.serial_connections =

        if self.serial_connections
        establish_ok = true
      end

      return establish_ok
    end
  end
end

