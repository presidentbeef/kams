require 'traits/sittable'

class Chair < GameObject
  include Sittable

  def initialize(*args)
    super
    @name = 'a nice chair'
    @generic = 'chair'
    @movable = false
  end
end
