#!/usr/local/bin/ruby

# The hem ruby client, the good one for Samotage

require 'hem_client'


SLEEPY_TIME = 5 # seconds

IS_PROD = true # sets where the API points

QUIET = false # if true, no output to screen.
WHINY = true  # if true, and not quiet, verbose output - otherwise minimal output.
NEEDY = true  # if true, it's like that.

while true do
  all_ok = false
  begin
    hem_client = HemClient::Client.new

    if hem_client != nil
      all_ok = hem_client.run_loop
    end

    if !all_ok
      if !QUIET
        puts "Back in main after the client returned FAIL..."
      end
    end
  rescue
    all_ok = false
  end

  if all_ok
    if !QUIET
      puts "---------refreshing the HEM client----------------------"
      puts " "
    end
    hem_client = nil
  else
    if !QUIET
      puts "something wierd is going on, so we have a little nap for #{SLEEPY_TIME} seconds"
      if !QUIET
        sleep(SLEEPY_TIME)
      end
    end
  end
end




