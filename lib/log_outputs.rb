
require "hem_objects"

module LogOutputs

  def LogOutputs.site_to_screen(site)

    puts site

    puts site.name
    puts site.type
    puts site.site_resource
    puts site.site_token
    puts site.last_ip_address
    puts site.poll_frequency
    puts site.poll_scatter

    site.devices.each do |device|

      puts   ".new.device." + device.serial
      puts   "............" + device.device_seq
      puts   "............" + device.device_resource
      puts   "............" + device.name
      puts   "............" + device.type

      device.commands.each do |command|
        puts   ".new_commad./...command..." + command.command_id
        puts   "............/...command..." + command.command_resource
        puts   "............/...command..." + command.comand_type
        puts   "............/...command..." + command.status
        puts   "............/...command..." + command.execute_at
        puts   "............/...command..." + command.executed_at
        puts   "............/...command..." + command.priority
        puts   "............/...command..." + command.confirm_type
      end

      device.streams.each do |stream|
        puts   ".new.stream./...stream..." + stream.ext_stream_id
        puts   "............/...stream..." + stream.stream_seq
        puts   "............/...stream..." + stream.stream_resource
        puts   "............/...stream..." + stream.updated_at
        puts   "............/...stream..." + stream.stream_type
        puts   "............/...stream..." + stream.unit_type
      end
    end

  end
    
end
