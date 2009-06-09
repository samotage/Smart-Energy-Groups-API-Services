
module ObjStreamPoint
  class ObjStreamPoint::StreamPoint
    attr_accessor :point_date
    attr_accessor :value

    attr_accessor :stream

    def initalize
      @point_date = nil
      @value = nil
    end

    def StreamPoint.make_point(value)
      point = ObjStreamPoint::StreamPoint.new

      point.point_date = Time.now
      point.value = value

      return point
    end
  end
end

