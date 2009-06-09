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

SERIAL_TIMEOUT = 3 # seconds
SERIAL_WAIT = 0.5 # seconds
SERIAL_TRY = 1 # second

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
          if !beating
            connection = nil
          end
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
    attr_accessor :usb_port
    attr_accessor :name
    attr_accessor :status
    attr_accessor :device
    
    attr_accessor :buffer
    
    def initialize
      @serial_connection = nil
      @name = "unknown"
      @status = "unknown"
      @buffer = nil
      @usb_port = nil

      @device = nil
    end

    def connection_open(path)
      begin
        self.serial_connection = open(path, File::RDWR | File::NONBLOCK)
        mode = self.serial_connection.fcntl(Fcntl::F_GETFL, 0)
        self.serial_connection.fcntl(Fcntl::F_SETFL, mode & ~File::NONBLOCK)
        self.usb_port = path
        return self.serial_connection
      rescue
        return nil
      end
    end

    def check_beating
      #TODO
      # this will listen on the connection's heartbeat to work out its controllerName
      heartbeat = false
      serial_data = serial_trx

      self.name = get_element("controllerName:", serial_data)
      puts self.name if !QUIET && WHINY
      if self.name != nil && self.name != ""
        heartbeat = true
        self.status = "Active"
        puts "...heartbeat on #{self.usb_port} identifies: #{self.name}" if !QUIET && WHINY
      end
      
      return heartbeat
    end

    def serial_trx(command=nil)
      # sends and recieves serial data, and returns an array of parsed sexpressions
      count = 0
      serial_output = nil
      output = nil
      
      while count < SERIAL_TRY do
        begin
          begin
            Timeout::timeout(SERIAL_TIMEOUT) do
              if command != nil
                self.serial_connection.puts "#{command};"
                sleep SERIAL_WAIT
              end
              while !self.serial_connection.eof
                serial_output = Array.new if !serial_output
                serial_feed = self.serial_connection.gets
                puts "...fresh from serial: #{serial_feed}" if !QUIET && WHINY && NEEDY
                serial_output << serial_feed
              end
            end
          rescue Timeout::Error
            puts "...serial connection has finished it's alloted read time."  if !QUIET && WHINY
          end
        rescue
          serial_output = nil
        end
        count += 1
        # we reach here when nothing was found...
        puts "...serial transaction read count: #{count}." if !QUIET
      end

      # Now parse the sexps
      output = parse_sexp(serial_output)

      return output
    end

    def parse_sexp(serial_output)
      output = nil
      serial_output.each do |sexp|
        begin
          if sexp != nil &&  sexp != ""
            puts "...got sexp: #{sexp} and about to parse" if !QUIET && WHINY && NEEDY
            output = Array.new if !output
            parsed_sexp = SExpression.parse(sexp)
            output << parsed_sexp
          end
        rescue
          puts "crud s-expression found: #{sexp} and skipped"
        end
      end
      return output
    end

    def get_element(name, elements)
      output = nil
      elements.each do |element|
        if element[0] == name
          output = element[1]
        end
      end
      return output
    end

    def print_sexp(sexp)
      if sexp != nil &&  sexp != ""
        puts sexp
      end
    end
  end
end



