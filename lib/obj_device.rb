
module ObjDevice
  class ObjDevice::Device
    attr_accessor :serial_num
    attr_accessor :index_seq
    attr_accessor :device_resource
    attr_accessor :name
    attr_accessor :type
    attr_accessor :status
    attr_accessor :switchable

    attr_accessor :serial_connection

    attr_accessor :site
    attr_accessor :streams, :commands

    def initialize
      @serial_num = nil
      @index_seq = nil
      @device_resource = nil
      @name = nil
      @type = nil
      @status = nil
      @switchable = nil

      @serial_connection = nil

      @streams = Array.new
      @commands = Array.new
    end
    
    def acquire_data
      acquired_data = false
      #TODO make fail on the fail of any single stream
      if self.serial_connection != nil
        puts "....acquiring raw data for device: #{self.serial_num}"  if !QUIET
        # Lets get some data for our serial connection
        fresh_data = self.serial_connection.serial_trx

        # now we have this, lets process it into the streams
        if fresh_data
          self.streams.each do |stream|
            acquired_data = stream.consume_data(self.serial_connection)
          end
        end
      end
      return acquired_data
    end

    def map_connection(connection)
      mapped = false
      if self.serial_num == connection.name
        self.serial_connection = connection
        connection.device = self
        mapped = true
      end
      return mapped
    end

    def assign_connection(connections)
      assigned = false
      connections.serial_connections.each do |serial_connection|
        if self.serial_num == serial_connection.name
          self.serial_connection = serial_connection
          serial_connection.device = self
          assigned = true
        end
      end
      return assigned
    end

    def synch_energisation
      synch_ok = true
      if self.switchable == "true"
        case self.status
        when "Active"
          synch_ok = self.execute_switch(ON)
        when "Inactive"
          synch_ok = self.execute_switch(OFF)
        else
          synch_ok = true
        end
      end
      return synch_ok
    end

    def execute_commands

      #TODO Put into the command objecto
      execute_ok = nil
      self.commands.each do |command|
        if command.status == "Executing" || command.status == "Execute Error"
          puts "about to execute command: #{command.command_type} on device: #{self.serial_num}"
          case command.command_type
          when "switch_on"
            execute_ok = self.execute_switch(ON, command)
          when "switch_off"
            execute_ok = self.execute_switch(OFF, command)
          else
          end
        end
      end
      return execute_ok
    end

    def execute_switch(value, command=nil )
      count = 0
      commanded = false

      if self.serial_connection != nil

        while count < COMMAND_TRY do
          result = nil
          begin
            puts "..device: #{self.serial_num} about to execute switch" if !QUIET && WHINY

            result = self.serial_connection.serial_trx(value, true)
            if result != nil
              if command != nil
                commanded = process_command_result(command, result)
                break if commanded
              else
                commanded = true
                break
              end
            end
          rescue Exception => e
            puts "..Something failed trying to execute the switch command: #{e.message}"
            puts e.backtrace.inspect
          end
          if commanded
            break
          end
          sleep(COMMAND_WAIT)
          count += 1
        end
      end
      return commanded
    end
    
  end
end


