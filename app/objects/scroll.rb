require 'lib/gameobject'
require 'traits/readable'

#A simple object for testing Readable module.
#
#===Info
# writable (Boolean)
class Scroll < GameObject
  include Readable

  def initialize(*args)
    super(*args)

    @generic = "scroll"
    @movable = true
    @short_desc = "a plain scroll"
    @long_desc = "This is simply a long piece of paper rolled up into a tight tube."
    @alt_names = ["plain scroll"]
    info.writable = true
  end
end
