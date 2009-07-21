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

DEFAULT_SITE_TOKEN = "site_42121f21b26e7adf0dece67f356090b07167f93a"

SERVER_TIMEOUT = 5 # seconds
MAIN_LOOP_COUNT = 100

HEM_COUNT = 10
HEM_WAIT = 3

STREAM_TRY = 3
STRAM_WAIT = 1

COMMAND_TRY = 3
COMMAND_WAIT = 1

ON = "(relay= on)"
OFF = "(relay= off)"

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

      self.serial_connections = UsbSerial::Connections.establish_serial_connections

      if !self.serial_connections
        puts "No serial connections found, and now exiting." if !QUIET
        return nil
      end

      beating = self.serial_connections.check_all_beating

      if !beating
        puts "No heartbeats found and exiting client." if !QUIET
        return nil
      end

      while count < MAIN_LOOP_COUNT do
        #loop flags...
        synch_ok = false
        got_data = false
        commands_ok = false
        put_site = false

        puts "  " if !QUIET
        puts "-------this is a new loop #{count}---------------------------------" if !QUIET
        if self.site != nil

          # connections need to be asssigned on each loop, as there is a new site each time!

          # The new way, driven by connections
          connections_assigned = self.site.map_connections(self.serial_connections)

          # The old way, driven by EM Devices
          # connections_assigned = self.site.assign_connections(self.serial_connections)

          if !connections_assigned
            puts "Serial connections could not be assigned to Energy manager devices and now exiting" if !QUIET
            return nil
          end

          if connections_assigned
            # we can do stuff
            # Do the stuff, first up synch!
            synch_ok = self.site.synch_energisation

            puts "Energisation synch failed" if !QUIET && WHINY && !synch_ok
            puts "Energisation synch Ok" if !QUIET && WHINY && synch_ok

            got_data = self.site.acquire_data

            # commands_ok = self.site.execute_commands

            if !QUIET && WHINY && commands_ok
              puts "  "
              puts "Executed Commands #{count}---------------------------------"
            end

            #     if got_data
            self.site = self.site.put_site
            if self.site
              puts "Acquired data sent to HEM" if !QUIET && WHINY
                
              puts "loop counter: #{count}" if !QUIET && WHINY

              if self.site.poll_frequency.to_i > 0
                puts "sleeping now: #{self.site.poll_frequency} seconds" if !QUIET && WHINY
                sleep(self.site.poll_frequency.to_i)
              else
                puts "No rest on this loop: #{self.site.poll_frequency} seconds" if !QUIET && WHINY
              end
            else
              puts "Something failed sending acquired data to HEM" if !QUIET
              sleep SERVER_TIMEOUT
            end
            #            else
            #              puts "This loop: #{count} has nothing to send to HEM"
            #              sleep SERVER_TIMEOUT
            #            end
          else
            # lets kill connections
            puts "serial connections not assigned, resetting before a retry" if !QUIET
            self.serial_connections = nil
            sleep SERVER_TIMEOUT
          end
        end
        count += 1
      end
      return count
    end
  end
end

