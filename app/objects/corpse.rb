require 'lib/gameobject'
require 'traits/expires'

#Corpses are left when something dies. Expires after a while.
class Corpse < GameObject
  include Expires

  def initialize(*args)
    super(*args)

    @generic = "corpse"
    @long_desc = "A smelly, rapidly decomposing corpse. Yuck."
    @movable = true
    expire_in 600
  end

  #Make this the corpse of the given Mobile.
  def corpse_of object
    @name = "corpse of #{object.name}"
    @alt_names << object.generic
    @alt_names += object.alt_names if object.alt_names
    @long_desc = "This is the empty and rapidly decomposing shell of #{object.name}."
  end
end
