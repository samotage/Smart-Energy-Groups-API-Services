require 'builder'

module BuildAskHem

  #
  #  Warning, this is subject to deprecation as this whole shebang is going to change.
  #

  def BuildAskHem.make_call_xml(*args)

    ext_stream_id = ""
    site_token = ""
    number_points = 0
    serial_num = ""
    date_time = Time.now
    point_value = 0
    make_data = false
    increment = 30
    command_id = ""
    command_status = ""
    command_executed = ""

    args.first.each do |key, value|
      case key
      when :site_token
        site_token = value
      when :ext_stream_id
        ext_stream_id = value
      when :serial_num
        serial_num = value
      when :command_id
        command_id = value
      when :command_status
        command_status = value
      when :command_executed
        command_executed = value
      when :date_time
        date_time = value
      when :number_points
        number_points = value
      when :value
        point_value = value
      end
    end

    xml = Builder::XmlMarkup.new(:target => $stdout, :indent => 2)
    # xml = Builder::XmlMarkup.new
    
    buffer = ""
    # xml = Builder::XmlMarkup.new(:target=>buffer)
    i = 0

    xml.instruct!
    xml.site do
      xml.site_token  site_token

      xml.devices do

        xml.serial_num = serial_num
        xml.streams do
          xml.stream do
            xml.ext_stream_id = ext_stream_id
            xml.points do
              if make_date != true
                xml.point do
                  xml.date_time date_time.strftime("%Y-%m-%d %H:%M:%S")
                  xml.value point_value
                end
              else
                while i < number_points do
                  xml.point do
                    #  2008-05-01 02:00:00
                    if make_data == true
                      # Add 30 mins in seconds.
                      date_time = date_time + (60 * increment)
                    end

                    xml.date_time date_time.strftime("%Y-%m-%d %H:%M:%S")

                    if make_data == true
                      data = Math.sin( i * 5 ) * 100
                      data += 110
                      xml.value data
                    else
                      xml.value point_value
                    end
                  end
                  i += 1
                end

              end
            end
          end
        end
        xml.commands do
          xml.command do
            xml.id = command_id
            xml.id = command_status
            xml.id = command_executed
          end
        end
      end
    end
    return buffer
  end
end
