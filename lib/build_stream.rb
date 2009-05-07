require 'builder'

module BuildStream

  #
  #  Warning, this is subject to deprecation as this whole shebang is going to change.
  #

  def BuildStream.make_stream_xml(*args)

    external_id = ""
    token = ""
    login = ""
    password = ""
    number_points = 0
    date_time = Time.now
    point_value = 0
    make_data = true
    increment = 30

    args.first.each do |key, value|
      case key
      when :external_id
        external_id = value
      when :token
        token = value
      when :login
        login = value
      when :password
        password = value
      when number_points
        number_points = value
      when :date_time
        date_time = value
      when :number_points
        number_points = value
      when :value
        point_value = value
      end
    end

    # Substitite to output the formatted XML to your happy monitor and nothing else.
    # xml = Builder::XmlMarkup.new(:target => $stdout, :indent => 2)
    
    buffer = ""
    xml = Builder::XmlMarkup.new(:target=>buffer)
    i = 0

    xml.instruct!
    xml.stream do
      xml.login       login
      xml.password    password
      xml.user_token  token
      xml.ext_stream_id external_id
      
      while i < number_points do
        xml.point do
          #  2008-05-01 02:00:00

          if make_data == true
            # Add 30 mins in seconds.
            date_time = date_time + (60 * 30)
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

    return buffer
    
  end
end
