require 'objects/container'

#An Area contains rooms and can be used to manage the weather and other area-wide information.
#Right now they don't do much but hold rooms, though.
#
#==Info
# info.terrain = Info.new
# info.terrain.area_type = :urban
class Area < Container

  def initialize(*args)
    super
    info.terrain = Info.new
    info.terrain.area_type = :urban
    @article = "an"
    @generic = "area"
  end

  #Returns self.
  def area
    self
  end
end
