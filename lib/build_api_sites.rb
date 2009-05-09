require 'builder'

module BuildApiSites

  #
  #  Warning, this is subject to deprecation as this whole shebang is going to change.
  #

  def BuildApiSites.make_put_xml(*args)

    site_token = ""
    ext_stream_id = ""
    device_serial_num = ""


    number_points = 0
    date_time = Time.now
    point_value = 0
    make_data = false
    increment = 30


    command_id = ""
    command_status = ""
    command_executed = Time.now.strftime("%Y-%m-%d %H:%M:%S")

    args.first.each do |key, value|
      case key
      when :site_token
        site_token = value
      when :ext_stream_id
        ext_stream_id = value
      when :device_serial_num
        device_serial_num = value
      when :command_id
        command_id = value
      when :command_status
        command_status = value
      when :command_executed
        command_executed = value
      when :make_data
        make_data = value
      when :date_time
        date_time = value
      when :number_points
        number_points = value
      when :value
        point_value = value
      end
    end

    buffer = ""

    # Toggle the following to put the XML out to the screen nicely formatted.
    #
    # Note, if it goes to the screen, it won't get to HEM... so to go to hem, make sure
    # the target is the buffer, not $stdout


    # xml = Builder::XmlMarkup.new(:target => $stdout, :indent => 2)
    xml = Builder::XmlMarkup.new(:target=>buffer)

    i = 0

    xml.instruct!
    xml.site do
      xml.site_token        site_token
      xml.devices do
        xml.device do
          xml.serial           device_serial_num

          xml.commands do
            xml.command do
              xml.command_id        command_id
              xml.status            command_status
              xml.executed_at       command_executed
            end
          end

          xml.streams do
            xml.stream do
              xml.ext_stream_id     ext_stream_id

              xml.points do
                if !make_data
                  # We send what's givn from parameters
                  xml.point do
                    xml.date_time date_time.strftime("%Y-%m-%d %H:%M:%S")
                    xml.value point_value
                  end
                else
                  # We're "manufacturing" data...
                  while i < number_points do
                    xml.point do
                      # Add 30 mins in seconds.

                      date_time = date_time + (60 * increment)
                      xml.date_time date_time.strftime("%Y-%m-%d %H:%M:%S")

                      data = Math.sin(i)
                      data = data * 100
                      data += 110
                      xml.value data
                    end
                    i += 1
                  end
                end
              end
            end
          end
        end
      end
    end
    return buffer
  end

end
