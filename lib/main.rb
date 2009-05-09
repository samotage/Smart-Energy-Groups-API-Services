
require 'rubygems'
require 'builder'
require "hem_adapter"
require "hem_objects"

# README
#
# This program doesn't represent any actual usefulness for your projects apart from demonstrating the
# useage of the various functions within the HEM adaptor.
#
# So test away as you please, and you can incorporate these method calls within your ruby project.
#
# Note you WILL need to get your site key, available within HEM when you edit your site.
#



# The following has a token for my site, so please be careful - and it is subject to change ;)

response = HemAdapter.send_command(:command => '/api_sites/site_f368b195a1d974457595a90416a312e11e48be94.xml',
                                    :method => :get)


site = HemAdapter.parse_response(:command => "api_sites",
                                  :method => :get,
                                  :xml_body => response)


