
module ObjSite
  class ObjSite::Site
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

    def assign_connections(serial_connections)
      assigned = false
      self.devices.each do |device|
        this_assigned = device.assign_connection(serial_connections)
        
        if !assigned && this_assigned
          # we assign success even if only one has made it.
          assigned = true
        end

      end
      return assigned
    end

    def synch_energisation
      synch_ok = false
      self.devices.each do |device|
        this_synch_ok = device.synch_energisation
        if !synch_ok && this_synch_ok
          # we assign success even if only one has made it.
          synch_ok = true
        end
      end
      return synch_ok
    end

    def execute_commands
      # go thorugh each site's devices and poll data for each of the streams...
      execute_ok = false

      self.devices.each do |device|
        #TODO Make this set fail if any of them fail...
        execute_ok = device.execute_commands
      end

      return execute_ok
    end


    def acquire_data
      # go thorugh each site's devices and poll data for each of the streams...
      acquired_data = false
      self.devices.each do |device|
        this_acquired_data = device.acquire_data
        if !acquired_data && this_acquired_data
          acquired_data = true
        end
      end
      return acquired_data
    end


    def Site.get_site(token)
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

    def put_site
      try_count = 0
      output_site = nil
      while try_count < HEM_COUNT
        response = nil
        begin
          begin
            xml_doc = BuildApiSites.site_to_xml(self)
            Timeout::timeout(SERVER_TIMEOUT) do
              if IS_PROD
                response = HemAdapter.send_command(
                  :command => "/api_sites/#{self.token}.xml",
                  :method => :put,
                  :options => {"data_post" => xml_doc})
              else
                response = HemAdapter.send_command(
                  :command => "/api_sites/#{self.token}.xml",
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
            output_site = ResponseParser.api_sites_xml(
              :command => "api_sites",
              :method => :get,
              :xml_body => response)

            if output_site
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
      return output_site
    end
   

    
    

  end
end

