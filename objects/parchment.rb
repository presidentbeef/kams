require 'lib/gameobject'
require 'traits/readable'

class Parchment < GameObject
  include Readable

  def initialize(*args)
    super(*args)

    @generic = "parchment"
    @movable = true
    @short_desc = "a piece of parchment"
    @long_desc = "a piece of parchment"
    @show_in_look = "A short piece of parchment is lying on the ground here."
    @name = "a piece of parchment"
    @alt_names = ["paper"]
  end
end
