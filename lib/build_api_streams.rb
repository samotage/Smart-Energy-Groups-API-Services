require 'builder'

module BuildApiStreams

  #
  #  Warning, this is subject to deprecation as this whole shebang is going to change.
  #

  def BuildApiStreams.make_stream_xml(*args)

    external_id = ""
    number_points = 0
    date_time = nil
    point_value = 0
    make_data = false
    increment = 30

    args.first.each do |key, value|
      case key
      when :external_id
        external_id = value
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

              if date_time
                date_time = date_time + (60 * increment)
                xml.point_date date_time.strftime("%Y-%m-%d %H:%M:%S")
              end

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
    return buffer
  end
end
