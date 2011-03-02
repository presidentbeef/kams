require 'lib/gameobject'

class Weapon < GameObject
  include Wearable

  def initialize(*args)
    super
    info.position = :wield
    info.weapon_type = nil
    info.attack = 0
    info.defense = 0
    info.layer = 0
    @movable = true
    @generic = "weapon"
  end
end
