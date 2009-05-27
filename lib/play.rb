

require 'rubygems'
require 'builder'
require "hem_adapter"
require "build_api_sites"
require "hem_objects"
require "response_parser"
require "log_outputs"


input = %|<?xml version="1.0" encoding="UTF-8"?><site><site_token>site_42121f21b26e7adf0dece67f356090b07167f93a</site_token><devices><device><serial>temp_001</serial><streams><stream><ext_stream_id>temp_001</ext_stream_id><points><point><date_time>2009-05-27 10:23:33</date_time><value>19.93</value></point></points></stream></streams></device></devices></site>|

#A local example, note the host and port

site = HemAdapter.send_command(
  :command => '/api_sites/site_42121f21b26e7adf0dece67f356090b07167f93a.xml',
  :method => :put,
  :options => {"data_post" => input },
  :host => "localhost",
  :port => 3000)



puts site



