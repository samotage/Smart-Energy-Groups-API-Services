
require 'net/http'
require 'nokogiri'
require "hem_objects"

LOG_SCREEN = true
  
module HemAdapter

  def HemAdapter.send_command(*args)

    command = ""
    method = :get
    options = ""
    

    # default ports for the api

    host = "api.smartenergygroups.com"
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
      if LOG_SCREEN
        puts command
      end

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
        # command << "?" + options.map{|k,v| "#{k}=#{v}" }.join('&')
        command
        req = Net::HTTP::Post.new(command)
        req.set_form_data(options)

      when :put
        # Set the form data with options
        req = Net::HTTP::Put.new(command)
        req.set_form_data(options)
      end

      response = http.request(req)

      if response.is_a?(Net::HTTPSuccess)
        if LOG_SCREEN
          puts "the adaptor command to HEM turned out just fine"
        end
      else
        if LOG_SCREEN
          puts "something went ka-boom with the HEM adaptor command..."
        end
      end
      return response.body
    end
  rescue Exception => e
    if LOG_SCREEN
      puts "The internetz have pwned your rqst within this adaptrix Net::HTTP #{ e } (#{ e.class })!"
    end
    return nil
  end
end
