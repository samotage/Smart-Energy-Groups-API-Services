
module ObjCommand
  class ObjCommand::Command
    attr_accessor :command_id
    attr_accessor :command_resource
    attr_accessor :command_type
    attr_accessor :status
    attr_accessor :execute_at
    attr_accessor :executed_at
    attr_accessor :priority
    attr_accessor :confirm_type

    attr_accessor :device

    def initialize
      @command_id = nil
      @command_resource = nil
      @command_type = nil
      @status = nil
      @execute_at = nil
      @executed_at = nil
      @priority = nil
      @confirm_type = nil
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
