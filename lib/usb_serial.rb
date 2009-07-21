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
#BAUDRATE = Termios::B9600

#SERIAL_TIMEOUT = 500 # seconds
SERIAL_TIMEOUT = 2 # seconds
SERIAL_WAIT = 0.2 # seconds
SERIAL_TRY = 3

DEVICE_PARAMETER = "nodeName="

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
            puts "Connected to device on path: #{path}" if !QUIET
            count += 1
          end
        rescue Exception => e
          puts "..failed to connect on device on path: #{path} message: #{e.message}" if !QUIET
        end
      end

      puts "Connected to: #{count} devices" if !QUIET
      return connections
    end

    def check_all_beating
      #TODO make a better beating check
      beating = true
      begin
        self.serial_connections.each do |connection|
          puts "..about to check heartbeat on: #{connection.usb_port}" if !QUIET
          beating = connection.check_beating
          if !beating
            puts puts "..no heartbeat on: #{connection.usb_port} and setting to nil" if !QUIET
            connection = nil
          end
        end
      rescue Exception => e
        puts "....failed to check heartbeats message: #{e.message}" if !QUIET
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
    
    #Buffer is used to read in data from the connection.
    attr_accessor :buffer
    attr_accessor :data_array
    
    def initialize
      @serial_connection = nil
      @name = "unknown"
      @status = "unknown"
      @usb_port = nil
      @device = nil
      @buffer = nil
      @data_array = nil
    end

    def connection_open(path)

      self.serial_connection = connection_init(path)

      self.serial_connection.extend Termios

      newtio = Termios::new_termios()
      newtio.ispeed = BAUDRATE
      newtio.ospeed = BAUDRATE

      Termios::tcflush(self.serial_connection, Termios::TCIOFLUSH)
      Termios::tcsetattr(self.serial_connection, Termios::TCSANOW, newtio)

      return self.serial_connection
    end

    def connection_flush
      # Termios::tcflush(self.serial_connection, Termios::TCIOFLUSH)
    end


    def connection_init(path)
      self.serial_connection = nil
      begin
        self.usb_port = path
        self.serial_connection = open(path, File::RDWR | File::NONBLOCK)
        mode = self.serial_connection.fcntl(Fcntl::F_GETFL, 0)
        self.serial_connection.fcntl(Fcntl::F_SETFL, mode & ~File::NONBLOCK)
      rescue Exception => e
        puts "..failed to open serial connection on path #{path} message: #{e.message}" if !QUIET && WHINY && NEEDY
        self.serial_connection = nil
      end
      return self.serial_connection
    end

    def check_beating
      heartbeat = false
      puts "....looking for heartbeat on #{self.usb_port}..." if !QUIET

      # Not returning first, and setting an overide timeout of 2 sections to listen to serial.
      serial_data = self.serial_trx(nil, false, 2)

      #TODO Make this retry if nothing useful found
      if serial_data
        self.name = get_value(DEVICE_PARAMETER, serial_data)
        if self.name != nil && self.name != ""
          heartbeat = true
          self.status = "Active"
          puts "....found heartbeat on #{self.usb_port} identifies: #{self.name}" if !QUIET && WHINY
        end
      end
      
      return heartbeat
    end

    def serial_trx(command=nil, return_first=nil, this_timeout=nil)
      # sends and recieves serial data, and returns an array of parsed sexpressions
      count = 0
      self.buffer = nil
      self.buffer = Array.new
      got_data = false
      
      if !this_timeout
        this_timeout = SERIAL_TIMEOUT
      end
      
      while count < SERIAL_TRY do
        begin
          begin
            Timeout::timeout(this_timeout) do

              if command != nil
                puts "......serial trx - about to send serial command: #{command}"
                self.serial_connection.puts command
                sleep 0.01
              end
              while !self.serial_connection.eof
                serial_feed = nil
                serial_feed = self.serial_connection.gets

                if serial_feed != nil
                  serial_chop = serial_feed.chop
                  if serial_chop != "" && serial_feed != "/n"
                    puts "......serial trx - recieved fresh serial data: #{serial_chop}" if !QUIET && WHINY && NEEDY
                    self.buffer << serial_chop
                    got_data = true
                    if return_first
                      break
                    end
                  end
                else
                  puts "......serial trx - received empty data..." if !QUIET && WHINY && NEEDY
                end
              end
            end
          rescue Timeout::Error
            puts "......serial trx - finished reading on serial connection: #{self.usb_port}."  if !QUIET && WHINY
          end
        rescue Exception => e
          puts "..an exception occured reading serial data, and exiting: #{e.message}"  if !QUIET && WHINY
        end

        if got_data
          break
        else
          count += 1
          # we reach here when nothing was found...
          puts "..serial trx - reading count: #{count}." if !QUIET
        end
      end

      # Now parse the sexps
      self.data_array = parse_sexp(self.buffer)
      if self.data_array != nil
        puts "......serial trx - serial transaction read count: #{count + 1}." if !QUIET
      end

      return self.data_array
    end

    def parse_sexp(serial_output)
      output = nil
      serial_output.each do |sexp|
        begin
          if sexp != nil &&  sexp != ""
            puts "........parsing raw s-exp: #{sexp}" if !QUIET && WHINY && NEEDY
            output = Array.new if !output
            parsed_sexp = SExpression.parse(sexp)
            output << parsed_sexp
          end
        rescue Exception => e
          puts "........crud s-expression found: #{sexp} and skipped, message: #{e.message}"
        end
      end
      return output
    end

    def get_value(name, elements)
      #returns a single value for a given name from an array of elements
      output = nil
      elements.each do |element|
        if element[0] == name
          output = element[1]
        end
      end
      return output
    end

    def get_values(name)
      #returns a single value for a given name from an array of elements
      output = nil
      self.data_array.each do |element|
        if element[0] == name
          output = Array.new if !output
          output << element[1]
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



