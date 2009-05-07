
require 'net/http'
require 'nokogiri'
require "hem_objects"
  
module HemAdapter

  def HemAdapter.send_command(*args)

    command = ""
    method = :get
    options = ""

    # default ports for the api
    #
    # This will be changing to api, however -
    # this version uses the hem subdomain, which will be deprecated.

    # host = "api.smartenergygroups.com"
    host = "hem.smartenergygroups.com"
    port = 80
    
    args.first.each do |key, value|
      case key
      when :command
        command = value
      when :options
        options = value
      when :method
        method = value
      when :host
        host = value
      when :port
        port = value
      end
    end

    # Open an HTTP connection to grid.smartenergygroups.com

    begin
      puts command

      http = Net::HTTP.new(host, port)
      headers={}
      # headers['Content-Type'] = "application/xml"
      headers['Content-Type'] = "multipart/form-data"

      # Depending on the request type, create either
      # an HTTP::Get or HTTP::Post object
      case method
      when :get
        # Append the options to the URL
        command << "?" + options.map{|k,v| "#{k}=#{v}" }.join('&')
        req = Net::HTTP::Get.new(command)

      when :post
        # Set the form data with options
        req = Net::HTTP::Post.new(command)
        req.set_form_data(options)

      when :put
        # Set the form data with options
        req = Net::HTTP::Put.new(command)
        req.set_form_data(options)
      end

      response = http.request(req)

      if response.is_a?(Net::HTTPSuccess)
        puts "the response from hem was all good"
      else
        puts "the response from hem indicated there was a problemo..."
      end
      return response.body
    end
  rescue Exception => e
    puts "The internetz have pwned your rqst within this adaptrix Net::HTTP #{ e } (#{ e.class })!"
  end

  def HemAdapter.parse_response(*args)

    # Parses the HEM Response to get commands, which are returned in an array.
    command = ""
    xml_body = ""
    options = ""
    output = nil
    method = ""
    site = nil

    args.first.each do |key, value|
      case key
      when :command
        command = value
      when :options
        # TODO - not at this time utilised.
        options = value
      when :xml_body
        xml_body = value
      when :method
        method = value
      end
    end

    if xml_body != nil
      doc = Nokogiri::XML.parse(xml_body)

      case method
      when :get
        case command
        when "api_sites"
          doc.search('//site').each do |site_element|

            #
            # Yes, the following could be kleener, but hey!
            #

            site = HemObjects::Site.new

            site.name = site_element.css('name').first.content
            site.site_token = site_element.css('site_token').first.content
            site.site_resource = site_element.css('site_resource').first.content
            site.last_ip_address = site_element.css('last_ip_address').first.content
            site.poll_frequency = site_element.css('poll_frequency').first.content
            site.poll_scatter = site_element.css('poll_scatter').first.content

            site_element.search('//devices').each do |devices_element|
              devices_element.search('//device').each do |device_element|
                device = HemObjects::Device.new

                device.serial = device_element.css('serial').first.content
                device.device_resource = device_element.css('device_resource').first.content
                device.name = device_element.css('name').first.content
                device.type = device_element.css('type').first.content
                
                devices_element.search('//commands').each do |commands_element|
                  commands_element.search('//command').each do |command_element|
                    
                    command = HemObjects::Command.new

                    command.command_id = command_element.css('command_id').first.content
                    command.command_resource = command_element.css('command_resource').first.content
                    command.comand_type = command_element.css('comand_type').first.content
                    command.status = command_element.css('status').first.content
                    command.execute_at = command_element.css('execute_at').first.content
                    command.executed_at = command_element.css('executed_at').first.content
                    command.priority = command_element.css('priority').first.content
                    command.confirm_type = command_element.css('confirm_type').first.content

                    device.commands << command
                  end
                end

                devices_element.search('//streams').each do |streams_element|
                  streams_element.search('//stream').each do |stream_element|

                    stream = HemObjects::Stream.new

                    stream.ext_stream_id = stream_element.css('ext_stream_id').first.content
                    stream.stream_resource = stream_element.css('stream_resource').first.content
                    stream.updated_at = stream_element.css('updated_at').first.content
                    stream.stream_type = stream_element.css('stream_type').first.content
                    stream.unit_type = stream_element.css('unit_type').first.content

                    device.streams << stream
                  end
                end

                site.devices << device

              end
            end
          end
          output = site
        else
          output = "Invalid command parsed"
        end
      when :put
      else
        output = "Invalid method parsed"
      end

      return output
    
    end
  end
end
