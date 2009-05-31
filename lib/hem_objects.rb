
module HemObjects
  class HemObjects::Site
    attr_accessor :name
    attr_accessor :type
    attr_accessor :token
    attr_accessor :site_resource
    attr_accessor :last_ip_address
    attr_accessor :poll_frequency
    attr_accessor :poll_scatter

    attr_accessor :devices

    def initialize
      @name = nil
      @type = nil
      @token = nil
      @site_resource = nil
      @last_ip_address = nil
      @poll_frequency = nil
      @poll_scatter = nil

      @devices = Array.new
    end
  end

  class HemObjects::Device
    attr_accessor :serial_num
    attr_accessor :index_seq
    attr_accessor :device_resource
    attr_accessor :name
    attr_accessor :type

    attr_accessor :streams, :commands

    def initialize
      @serial_num = nil
      @index_seq = nil
      @device_resource = nil
      @name = nil
      @type = nil

      @streams = Array.new
      @commands = Array.new
    end
  end

  class HemObjects::Command
    attr_accessor :command_id
    attr_accessor :command_resource
    attr_accessor :comand_type
    attr_accessor :status
    attr_accessor :execute_at
    attr_accessor :executed_at
    attr_accessor :priority
    attr_accessor :confirm_type

    def initialize
      @command_id = nil
      @command_resource = nil
      @comand_type = nil
      @status = nil
      @execute_at = nil
      @executed_at = nil
      @priority = nil
      @confirm_type = nil
    end
  end

  class HemObjects::Stream
    attr_accessor :external_id
    attr_accessor :sequence
    attr_accessor :stream_resource
    attr_accessor :updated_at
    attr_accessor :stream_type
    attr_accessor :unit_type
    attr_accessor :parameter
    
    attr_accessor :points

    def initalize
      @external_id = nil
      @sequence = nil
      @stream_resource = nil
      @updated_at = nil
      @stream_type = nil
      @unit_type = nil
      @parameter = nil

      @points = Array.new
    end
  end

  class HemObjects::StreamPoint
    attr_accessor :point_date
    attr_accessor :value

    def initalize
      @point_date = nil
      @value = nil
    end
  end
    
end
