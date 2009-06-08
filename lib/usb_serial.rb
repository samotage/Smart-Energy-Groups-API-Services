#!/usr/local/bin/ruby

require 'rubygems'
require 'fcntl'
require 'termios'
require 'timeout'

require "s_expression"

USB0 = '/dev/ttyUSB0'
USB1 = '/dev/ttyUSB1'
USB2 = '/dev/ttyUSB2'
USB3 = '/dev/ttyUSB3'
USB4 = '/dev/ttyUSB4'

DEVICE_PATHS = [USB0, USB1, USB2, USB3]

BAUDRATE = Termios::B115200

SERIAL_TRY = 2000
SERIAL_TIMEOUT = 1
SERIAL_WAIT = 0.002 # seconds
SERIAL_TIMEOUT_TRY = 3

module UsbSerial

  class UsbSerial::Connections
    attr_accessor :serial_connections

    def initialize
      @serial_connections = Array.new
    end

    def Connections.establish_serial_connections(index=nil)
      count = 0
      connections = UsbSerial::Connections.new

      DEVICE_PATHS.each do |path|
        begin
          connection = UsbSerial::Connection.new
          connection.serial_connection = connection.connection_open(path)
          if connection.serial_connection != nil
            connections.serial_connections << connection
            puts "" if !QUIET
            puts "Connected to device on path: #{path}" if !QUIET
            count += 1
          end
        rescue
          puts "Fail to connect on device on path: #{path}" if !QUIET
        end
      end

      puts "Connected to: #{count} devices" if !QUIET
      return connections
    end

    def check_all_beating
      beating = true
      begin
        self.serial_connections.each do |connection|
          beating = connection.check_beating
        end
      rescue
        beating = false
      end
      return beating
    end

    def flush_connections(index=nil)
      self.serial_connections = nil
      self.serial_connections = establish_connections(index)
      return self.serial_connection
    end
  end
  
  class UsbSerial::Connection
    attr_accessor :serial_connection
    attr_accessor :name
    attr_accessor :status
    attr_accessor :device
    
    attr_accessor :buffer
    
    def initialize
      @serial_connection = nil
      @name = "unknown"
      @status = "unknown"
      @buffer = nil

      @device = nil
    end

    

    def connection_open(path)
      begin
        self.serial_connection = open(path, File::RDWR | File::NONBLOCK)
        mode = self.serial_connection.fcntl(Fcntl::F_GETFL, 0)
        self.serial_connection.fcntl(Fcntl::F_SETFL, mode & ~File::NONBLOCK)
        return self.serial_connection
      rescue
        return nil
      end
    end

    def check_beating
      #TODO
      # this will listen on the connection's heartbeat
      # and workout wether it should be added
      self.name = "switch_001"
      self.status = "Active"

      return true
    end

    def serial_trx(command=nil)
      # sends and recieves serial data, and return the parsed sexpression
      count = 0
      while count < SERIAL_TIMEOUT_TRY do
        sexp = nil
        success = false
        result = nil
        begin
          begin
            Timeout::timeout(SERIAL_TIMEOUT) do
              if command != nil
                self.serial_connection.puts command
                sleep 0.005
              end
              sexp = self.serial_connection.gets
            end
          rescue Timeout::Error
            if count > SERIAL_TIMEOUT_TRY
              puts "...serial connection timeout count limit reached, and exiting."  if !QUIET
              break
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
          puts "...the program became upset parsing the s-expression: #{sexp} on attempt #{count}." if !QUIET
        end
        # puts "serial try #{count}"
        count += 1
      end
      # we reach here when nothing was found...
      puts "...exited serial transaction on count: #{count}." if !QUIET
      return result if success
      return nil
    end

    def parse_sexp(sexp)
      result = nil
      if sexp != nil &&  sexp != ""
        puts "...got sexp: #{sexp} and about to parse" if !QUIET && WHINY
        result = SExpression.parse(sexp)
      end
      return result if result.size > 0
      return false
    end

    def print_sexp(sexp)
      if sexp != nil &&  sexp != ""
        puts sexp
      end
    end
  end
end



