require "objects/weapon"

class Dagger < Weapon

  def initialize(*args)
    super
    @generic = "dagger"
    info.weapon_type = :dagger
    info.attack = 5
    info.defense = 5
  end
end
