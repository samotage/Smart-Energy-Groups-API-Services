
module ObjStream
  class ObjStream::Stream
    attr_accessor :external_id
    attr_accessor :sequence
    attr_accessor :stream_resource
    attr_accessor :updated_at
    attr_accessor :stream_type
    attr_accessor :unit_type
    attr_accessor :parameter
    attr_accessor :aggregation_rule

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
      @aggregation_rule = nil

      @points = Array.new
    end


    def poll_data(serial)
      count = 1
      acquired_data = false
      if self.parameter != nil && self.parameter != ""
        # we are looking for s expressions on the serial feed that match our stream's parameter

        while count < STREAM_TRY do
          begin
            if !QUIET && WHINY
              puts "about to get sexp, count: #{count}"
            end
            fresh_data = serial.serial_trx

            if fresh_data
              values = serial.get_values(self.parameter, fresh_data)
              
              if values != nil && values.size > 0
                acquired_data = process_data(values)
              end
              break if acquired_data
            end
          rescue Exception => e
            if !QUIET
              puts "...something failed aquiring stream data and adding point, message: #{e.message}"
              puts e.backtrace.inspect
            end
          end
          if !QUIET && WHINY
            puts "...looking for value #{stream.parameter} attempt #{count}"
          end
          sleep(STREAM_WAIT)
          count += 1
        end
      end
      return acquired_data
    end

    def consume_data(serial_connection)

      #we get the data out of the data_array on the serial connection and put into the stream

      begin
        if !QUIET && WHINY
          puts "....about process serial data into stream: #{self.external_id}"
        end

        if serial_connection
          values = serial_connection.get_values(self.parameter)

          if values != nil && values.size > 0
            acquired_data = process_data(values)
          end
        end
      rescue Exception => e
        if !QUIET
          puts "....something failed aquiring stream data and adding point, message: #{e.message}"
          puts e.backtrace.inspect
        end
      end
    end

    def process_data(fresh_data)
      value = nil

      fresh_data.each do |this_value|
        case self.aggregation_rule
        when "average"
          value = 0 if !value
          value += this_value.to_f
        when "sum"
          value = 0 if !value
          value += this_value.to_f
        end
      end

      if self.aggregation_rule == "average"
        # work out the average
        average_div = fresh_data.size
        if value != nil && average_div != nil && average_div > 0
          #avoid div zero...
          average = value/average_div
          value = average
        end
      end
      acquired_data = add_stream_point(value)

      return acquired_data
    end

    def add_stream_point(value)
      added_point = false
      stream_point = ObjStreamPoint::StreamPoint.make_point(value.to_s)
      stream_point.stream = self

      if self.points == nil
        self.points = Array.new
      end
      self.points << stream_point
      added_point = true
      puts "...acquired: #{self.parameter} #{value} at #{stream_point.point_date.strftime("%Y-%m-%d %H:%M:%S")}" if !QUIET
      return added_point
    end
  end
end
