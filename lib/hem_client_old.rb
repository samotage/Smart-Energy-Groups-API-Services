#!/usr/local/bin/ruby

require 'rubygems'
require 'builder'
require 'fcntl'
require 'termios'
require 'timeout'

require "hem_adapter"
require "build_api_sites"
require "hem_objects"
require "response_parser"
require "log_outputs"
require "s_expression"


IS_PROD = false

USB0 = '/dev/ttyUSB0'
USB1 = '/dev/ttyUSB1'
USB2 = '/dev/ttyUSB2'
USB3 = '/dev/ttyUSB2'
USB4 = '/dev/ttyUSB2'
S0 = '/dev/ttyS0'
S1 = '/dev/ttyS1'
S2 = '/dev/ttyS2'
S3 = '/dev/ttyS3'
S4 = '/dev/ttyS4'

DEVICE_PATHS = [USB0, USB1, USB2, USB3]

BAUDRATE = Termios::B115200

MAIN_LOOP_COUNT = 1

HEM_COUNT = 10
HEM_WAIT = 3

SERIAL_TRY = 2000
SERIAL_TIMEOUT = 1
SERIAL_WAIT = 0.002 # seconds
SERIAL_TIMEOUT_TRY = 3

STREAM_TRY = 3
STRAM_WAIT = 1

COMMAND_TRY = 3
COMMAND_WAIT = 1

HIGH = "H"
LOW = "L"

DEFAULT_SITE_TOKEN = "site_42121f21b26e7adf0dece67f356090b07167f93a"

module HemClient

  class HemClient::Client
    attr_accessor :serial_conn
    attr_accessor :site_token
    attr_accessor :site_keys
    attr_accessor :site_working
    attr_accessor :value_array

    def initialize
      @site_token = DEFAULT_SITE_TOKEN
      @value_array = Array.new

      if !QUIET
        puts ""
        puts "###########################################################################"
        puts "---Establishing Client-----------------------------------------"
        if IS_PROD
          env = "Production"
        else
          env = "Development"
        end
        puts "---Environment is: #{env}"
      end
    end

    def find_and_open_device(device_array, index=nil)
      device = nil

      device_array.each do |path|
        begin
          device = dev_open(path)
          if device != nil
            if !QUIET
              puts ""
              puts "Connected to device on path: #{path}"
            end
            break
          end
        rescue
          if !QUIET
            puts "Fail to connect on device on path: #{path}"
          end
        end
      end
      if !QUIET
        puts ""
      end
      return device
    end

    def dev_open(path)
      dev = open(path, File::RDWR | File::NONBLOCK)
      mode = dev.fcntl(Fcntl::F_GETFL, 0)
      dev.fcntl(Fcntl::F_SETFL, mode & ~File::NONBLOCK)
      return dev
    end

    def dev_flush
      self.serial_conn = nil
      self.serial_conn = find_and_open_device(DEVICE_PATHS)
      return self.serial_conn
    end

    def read_sexp(sexp)
      if sexp != nil &&  sexp != ""
        puts sexp
      end
    end

    def prep_loop
      # get the working site for the inital loop
      self.site_working = get_site(self.site_token)
    end

    def run_loop
      count = 0
      prep_loop
      while count < MAIN_LOOP_COUNT do
        synch_ok = false
        got_data = false
        commands_ok = false
        put_site = false
        if !QUIET
          puts "  "
          puts "-------this is a new loop #{count}---------------------------------"
        end

        if self.site_working != nil
          # Do the stuff, first up synch!

          synch_ok = synch_energisation(self.site_working)

          # got_data = acquire_site_data(self.site_working)

          if !QUIET && WHINY && !synch_ok
            puts "-------Synch failed"
          end

          if !QUIET && WHINY && got_data
            puts "  "
            puts "-------Got stream data #{count}---------------------------------"
          end

          commands_ok = execute_commands(self.site_working)

          if !QUIET && WHINY && commands_ok
            puts "  "
            puts "-------Executed Commands #{count}---------------------------------"
          end

          if !QUIET && WHINY && got_data && commands_ok
            puts "Nothing to do on loop: #{count}"
          end

          put_site = put_site(self.site_working)
          if put_site
            if !QUIET && WHINY
              puts "Acquired data sent to HEM"
            end
          else
            if !QUIET && WHINY
              puts "Something failed sending acquired data to HEM"
            end
            got_data = false
          end

          count += 1
          if !QUIET && WHINY
            puts "loop counter: #{count}"
          end
          if !QUIET
            puts "sleeping now: #{self.site_working.poll_frequency} seconds"
          end
          sleep(self.site_working.poll_frequency.to_i)
        else
          return false
        end
      end
      return count
    end

    def put_site(site)
      try_count = 0
      while try_count < HEM_COUNT
        response = nil
        success_ind = false
        begin
          begin
            xml_doc = BuildApiSites.site_to_xml(site)
            Timeout::timeout(SERVER_TIMEOUT) do
              if IS_PROD
                response = HemAdapter.send_command(
                  :command => "/api_sites/#{site.token}.xml",
                  :method => :put,
                  :options => {"data_post" => xml_doc})
              else
                response = HemAdapter.send_command(
                  :command => "/api_sites/#{site.token}.xml",
                  :method => :put,
                  :options => {"data_post" => xml_doc},
                  :host => "localhost",
                  :port => 3000)
              end
            end
          rescue Timeout::Error
            if !QUIET
              puts "...timeout in HEM Put command, attempt count: #{try_count}"
            end
            return false
          end
          if response != nil
            self.site_working = ResponseParser.api_sites_xml(
              :command => "api_sites",
              :method => :get,
              :xml_body => response)

            if self.site_working
              success_ind = true
              break
            end
          end
        rescue
          if !QUIET
            puts "...call to get site from HEM failed, attempt count: #{try_count}"
          end
        end

        if !QUIET && WHINY
          puts "...trying again to :put site into HEM, attempt count: #{try_count}"
        end
        try_count += 1
        sleep HEM_WAIT
      end
      return success_ind
    end

    def get_site(token)
      try_count = 0
      while try_count < HEM_COUNT
        site = nil
        response = nil
        begin
          begin
            Timeout::timeout(SERVER_TIMEOUT) do
              if IS_PROD
                response = HemAdapter.send_command(
                  :command => "/api_sites/#{token}.xml",
                  :method => :get)
              else
                response = HemAdapter.send_command(
                  :command => "/api_sites/#{token}.xml",
                  :method => :get,
                  :host => "localhost",
                  :port => 3000)
              end
            end
          rescue Timeout::Error
            if !QUIET
              puts "...timeout in HEM Get command, attempt count: #{try_count}"
            end
          end
          if response != nil
            site = ResponseParser.api_sites_xml(
              :command => "api_sites",
              :method => :get,
              :xml_body => response)
            break if site
          end
        rescue
          if !QUIET
            puts "...call to get site from HEM failed, attempt count: #{try_count}"
          end
        end
        if !QUIET && WHINY
          puts "...trying again to :get site from HEM, attempt count: #{try_count}"
        end

        try_count += 1
        sleep HEM_WAIT
      end

      return site
    end

    def acquire_site_data(site)
      # go thorugh each site's devices and poll data for each of the streams...
      acquired_data = false
      site.devices.each do |device|
        device.streams.each do |stream|

          if stream.parameter != nil && stream.parameter != ""
            acquired_data = poll_device_stream(stream)
          end
        end
      end
      return acquired_data
    end

    def serial_trx(command=nil)
      # sends and recieves serial data, and return the parsed sexpression
      count = 0
      self.serial_conn = dev_flush
      if self.serial_conn != nil
        while count < SERIAL_TIMEOUT_TRY do
          sexp = nil
          success = false
          result = nil
          begin
            begin
              Timeout::timeout(SERIAL_TIMEOUT) do
                if command != nil
                  self.serial_conn.puts command
                  sleep 0.005
                end
                sexp = self.serial_conn.gets
              end
            rescue Timeout::Error
              if !QUIET
                self.serial_conn = dev_flush
                if count > SERIAL_TIMEOUT_TRY
                  puts "...serial connection timed out."
                  break
                end
              end
            end
          rescue
            sexp = nil
          end
          begin
            if sexp != nil
              result = parse_sexp(sexp)
              if result != nil
                success = true
                break
              end
            end
          rescue
            if !QUIET
              puts "...the program became upset parsing the s-expression: #{sexp} on attempt #{count}."
            end
          end
          # puts "serial try #{count}"
          count += 1
        end
        # we reach here when nothing was found...
        if !QUIET
          puts "...exited serial transaction on count: #{count}."
        end
      end
      return result if success
      return nil
    end

    def parse_sexp(sexp)
      result = nil
      if sexp != nil &&  sexp != ""
        if !QUIET && WHINY
          puts "...got sexp: #{sexp} and about to parse"
        end
        result = SExpression.parse(sexp)
      end

      return result if result.size > 0
      return false
    end

    def poll_device_stream(stream)
      count = 1
      acquired_data = false
      # we are looking for s expressions on the serial feed that match our stream's parameter

      while count < STREAM_TRY do
        value = nil
        begin
          if !QUIET && WHINY
            puts "about to get sexp, count: #{count}"
          end
          value = serial_trx
          if value != nil
            acquired_data = add_stream_point(stream, value)
            break if acquired_data
          end
        rescue
          if !QUIET
            puts "...something failed aquiring stream data and adding point"
          end
        end
        if !QUIET && WHINY
          puts "...looking for value #{stream.parameter} attempt #{count}"
        end
        sleep(STREAM_WAIT)
        count += 1
      end
      return acquired_data
    end

    def add_stream_point(stream, value)
      added_point = false
      if value != nil
        if value[0] == stream.parameter
          if value[1] != nil
            stream_point = ObjStreamPoint::StreamPoint.new
            stream_point.point_date = Time.now
            stream_point.value = value[1].to_s

            if stream.points == nil
              stream.points = Array.new
            end
            stream.points << stream_point
            added_point = true
            if !QUIET
              puts "...acquired: #{stream.parameter} #{value} at #{stream_point.point_date.strftime("%Y-%m-%d %H:%M:%S")}"
            end
          end
        end
      end
      return added_point
    end

    def execute_commands(site)
      # go thorugh each site's devices and poll data for each of the streams...
      execute_ok = false
      site.devices.each do |device|
        device.commands.each do |command|
          if command.status == "Executing" || command.status == "Execute Error"
            puts "about to send command: #{command.command_type} to device: #{device.serial_num} "
            case command.command_type
            when "switch_on"
              execute_ok = execute_switch(HIGH, command)
            when "switch_off"
              execute_ok = execute_switch(LOW, command)
            else
            end
          end
        end
      end
      return execute_ok
    end

    def synch_energisation(site)
      synch_ok = false
      site.devices.each do |device|
        if device.switchable == "true"
          case device.status
          when "Active"
            synch_ok = execute_switch("H")
          when "Inactive"
            synch_ok = execute_switch("L")
          else
            synch_ok = true
          end
        end
      end
      return synch_ok
    end

    def execute_switch(value, command=nil )
      count = 0
      commanded = false
      while count < COMMAND_TRY do
        result = nil
        begin
          if !QUIET && WHINY

          end
          result = serial_trx(value)
          if result != nil
            if command != nil
              commanded = process_command_result(command, result)
              break if commanded
            else
              commanded = true
              break
            end
          end
        rescue
          if !QUIET
            puts "...Boo. Something exploded tying to send the command."
          end
        end
        if commanded
          break
        end
        sleep(COMMAND_WAIT)
        count += 1
      end
      return commanded
    end

    def process_command_result(command, result)
      commanded = false
      if result[0] == "command="
        case result[1]
        when "on"
          if command.command_type == "switch_on"
            command.status = "Complete"
            command.executed_at = Time.now
            commanded = true
          end
        when "off"
          if command.command_type == "switch_off"
            command.status = "Complete"
            command.executed_at = Time.now
            commanded = true
          end
        else
          if !QUIET && WHINY
            puts "an unknown result when executing: #{command.command_type} for device: #{device.serial_num} of: #{result[0]} #{result[1]}"
          end
          command.status = "Execute Error"
          commanded = false
        end
      end
      return commanded
    end
  end
end



