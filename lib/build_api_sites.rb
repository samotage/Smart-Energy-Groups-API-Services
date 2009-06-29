require 'builder'

module BuildApiSites

  #
  #  Warning, this is subject to deprecation as this whole shebang is going to change.
  #

  def BuildApiSites.site_to_xml(site)
    buffer = ""

    # Toggle the following to put the XML out to the screen nicely formatted.
    #
    # Note, if it goes to the screen, it won't get to HEM... so to go to hem, make sure
    # the target is the buffer, not $stdout

    # xml = Builder::XmlMarkup.new(:target => $stdout, :indent => 2)
    xml = Builder::XmlMarkup.new(:target=>buffer)

    xml.instruct!

    xml.site do

      xml.name         site.name
      xml.token        site.token

      xml.devices do
        site.devices.each do |device|
          xml.device  do
            xml.serial_num           device.serial_num
            xml.index_seq            device.index_seq

            xml.commands do
              device.commands.each do |command|
                xml.command do
                  xml.command_id        command.command_id
                  xml.status            command.status
                  xml.executed_at       command.executed_at
                end
              end
            end

            xml.streams do
              device.streams.each do |stream|
                xml.stream do
                  xml.external_id     stream.external_id
                  xml.sequence        stream.sequence
                  xml.parameter        stream.parameter

                  if stream.points != nil &&  stream.points.size > 0
                    xml.points do
                      stream.points.each do |point|
                        xml.point do
                          xml.point_date    point.point_date.strftime("%Y-%m-%d %H:%M:%S")
                          xml.value         point.value.to_s
                        end
                      end
                    end
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

  def BuildApiSites.make_put_xml(*args)

    token = ""
    external_id = ""
    device_serial_num = ""

    number_points = 0
    date_time = Time.now
    point_value = 0
    command_action = false
    make_data = false
    increment = 30

    command_id = ""
    command_status = ""
    command_executed = Time.now.strftime("%Y-%m-%d %H:%M:%S")

    args.first.each do |key, value|
      case key
      when :token
        token = value
      when :external_id
        external_id = value
      when :device_serial_num
        device_serial_num = value
      when :command_action
        command_action = value
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
      xml.token        token
      xml.devices do
        xml.device do
          xml.serial_num           device_serial_num

          if command_action
            xml.commands do
              xml.command do
                xml.command_id        command_id
                xml.status            command_status
                xml.executed_at       command_executed
              end
            end
          end

          xml.streams do
            xml.stream do
              xml.external_id     external_id

              xml.points do
                if !make_data
                  # We send what's givn from parameters
                  xml.point do
                    xml.point_date date_time.strftime("%Y-%m-%d %H:%M:%S")
                    xml.value point_value
                  end
                else
                  # We're "manufacturing" data...
                  while i < number_points do
                    xml.point do
                      # Add 30 mins in seconds.

                      date_time = date_time + (60 * increment)
                      xml.point_date date_time.strftime("%Y-%m-%d %H:%M:%S")

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
