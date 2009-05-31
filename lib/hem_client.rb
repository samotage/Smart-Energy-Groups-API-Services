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


IO_SPEED = 115200
LOOP_COUNT = 20
IS_PROD = true

## Sam's Home
#site_token = "site_42121f21b26e7adf0dece67f356090b07167f93a"

# home temp
#serial_num = "temp_001"
#external_id = "temp_001"

## sam's shed temp
#serial_num = "temp_003"
#external_id = "temp_003"

## Sam's Office
#site_token = "site_3074eb0861efa6dca67c3d7334a297520c3d2201"
#serial_num = "temp_002"
#external_id = "temp_002"


module HemClient
  class HemClient::Client
    attr_accessor :serial_conn
    attr_accessor :site_token
    attr_accessor :site_keys
    attr_accessor :site_working
    attr_accessor :value_array
    
    def initialize
      @site_token = "site_42121f21b26e7adf0dece67f356090b07167f93a"
      @value_array = Array.new
      begin
        @serial_conn = File.open("/dev/ttyUSB0")
      rescue
        begin
          @serial_conn = File.open("/dev/ttyUSB1")
        rescue
          @serial_conn = File.open("/dev/ttyUSB2")
        end
      end
      if @serial_conn != nil
        tio = Termios.tcgetattr(@serial_conn)
        tio.ispeed = tio.ospeed = IO_SPEED
        Termios.tcsetattr(@serial_conn, Termios::TCSANOW, tio)
      else
        return nil
      end
    end

    def prep_loop
      # get the working site for the inital loop
      self.site_working = get_site(self.site_token)
    end

    def run_loop
      count = 0
      count_max = LOOP_COUNT

      prep_loop

      while count < count_max do
        if !QUIET
          puts "  "
          puts "-------this is a new loop #{count}---------------------------------"
        end
        if self.site_working != nil
          got_data = acquire_site_data
          if got_data
            got_data = put_site(self.site_working)
            if got_data
              if !QUIET && WHINY
                puts "Acquired data sent to HEM"
              end
            else
              if !QUIET && WHINY
                puts "Something failed sending acquired data to HEM"
              end
              got_data = false
            end
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
      return got_data
    end

    def put_site(site)
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

          self.site_working = ResponseParser.api_sites_xml(
            :command => "api_sites",
            :method => :get,
            :xml_body => response)
        end
        # note the setup for the next loop is in this put response.
        
      rescue Timeout::Error, Errno::ECONNREFUSED
        if !QUIET
          puts "...timeout in HEM Put command"
        end
        return false
      end
      return true
    end

    def get_site(token)
      response = nil
      site = nil
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
        if response != nil
          site = ResponseParser.api_sites_xml(
            :command => "api_sites",
            :method => :get,
            :xml_body => response)
        end
      rescue Timeout::Error, Errno::ECONNREFUSED
        if !QUIET
          puts "...timeout in HEM Get command"
        end
        return nil
      end
      return site
    end

    def acquire_site_data
      # go thorugh each site's devices and poll data for each of the streams...
      acquired_data = false
      self.site_working.devices.each do |device|
        device.streams.each do |stream|

          if stream.parameter != nil && stream.parameter != ""
            acquired_data = poll_device_stream(stream)
          end
        end
      end
      return acquired_data
    end

    def poll_device_stream(stream)
      count = 1
      countout = 15
      acquired_data = false
      # we are looking for s expressions on the serial feed that match our stream's parameter
      if stream != nil && stream != ""
        # then we 'ave something to acquire
        while count < countout do
          begin
            result = nil
            s_exp = nil
            if !QUIET && WHINY
              puts "about to get s_exp, count: #{count}"
            end
            Timeout::timeout(SERVER_TIMEOUT) do
              s_exp = self.serial_conn.gets
            end
            if !QUIET && WHINY
              puts "got s_exp and about to parse"
            end
            if s_exp != nil &&  s_exp != ""
              result = SExpression.parse(s_exp)
              if result != nil
                if result[0] == stream.parameter
                  if result[1] != nil
                    # lets add value!
                    add_stream_point(stream, result[1])
                    acquired_data = true
                    break
                  end
                end
              end
            end

          rescue Timeout::Error, Errno::ECONNREFUSED
            if !QUIET
              puts "...serial connection timed out, strange?"
            end
          end
          if !QUIET && WHINY
            puts "...looking for value #{stream.parameter} attempt #{count}"
          end
          sleep(SERIAL_WAIT)
          count += 1
        end
      end
      return acquired_data
    end

    def add_stream_point(stream, value)
      # for a peculiar reason, this didn't work...

      stream_point = HemObjects::StreamPoint.new
      stream_point.point_date = Time.now
      stream_point.value = value.to_s

      if stream.points == nil
        stream.points = Array.new
      end
      stream.points << stream_point
      if !QUIET
        puts "...acquired: #{stream.parameter} #{value} at #{stream_point.point_date.strftime("%Y-%m-%d %H:%M:%S")}"
      end
    end
  end
end



