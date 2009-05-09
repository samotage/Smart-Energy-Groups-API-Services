
require 'net/http'
require 'nokogiri'
require "hem_objects"
  
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
        puts "the response from HEM was all good"
      else
        puts "the response from HEM indicated there was a problemo..."
      end
      return response.body
    end
  rescue Exception => e
    puts "The internetz have pwned your rqst within this adaptrix Net::HTTP #{ e } (#{ e.class })!"
  end
end
