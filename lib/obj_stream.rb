
module ObjStream
  class ObjStream::Stream
    attr_accessor :external_id
    attr_accessor :sequence
    attr_accessor :stream_resource
    attr_accessor :updated_at
    attr_accessor :stream_type
    attr_accessor :unit_type
    attr_accessor :parameter

    attr_accessor :device
    attr_accessor :points

    def initalize
      @external_id = nil
      @sequence = nil
      @stream_resource = nil
      @updated_at = nil
      @stream_type = nil
      @unit_type = nil
      @parameter = nil

      @points = Array.new
    end


    def poll_device_stream(stream)
      count = 1
      acquired_data = false
      # we are looking for s expressions on the serial feed that match our stream's parameter

      while count < STREAM_TRY do
        value = nil
        begin
          if !QUIET && WHINY
            puts "about to get sexp, count: #{count}"
          end
          value = serial_trx
          if value != nil
            acquired_data = add_stream_point(stream, value)
            break if acquired_data
          end
        rescue
          if !QUIET
            puts "...something failed aquiring stream data and adding point"
          end
        end
        if !QUIET && WHINY
          puts "...looking for value #{stream.parameter} attempt #{count}"
        end
        sleep(STREAM_WAIT)
        count += 1
      end
      return acquired_data
    end

    def add_stream_point(stream, value)
      added_point = false
      if value != nil
        if value[0] == stream.parameter
          if value[1] != nil
            stream_point = ObjStreamPoint::StreamPoint.new
            stream_point.stream = self
            
            stream_point.point_date = Time.now
            stream_point.value = value[1].to_s

            if stream.points == nil
              stream.points = Array.new
            end
            stream.points << stream_point
            added_point = true
            if !QUIET
              puts "...acquired: #{stream.parameter} #{value} at #{stream_point.point_date.strftime("%Y-%m-%d %H:%M:%S")}"
            end
          end
        end
      end
      return added_point
    end

    
  end
end
