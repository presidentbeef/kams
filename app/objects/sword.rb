require "objects/weapon"

class Sword < Weapon

  def initialize(*args)
    super
    @generic = "sword"
    info.weapon_type = :sword
    info.attack = 10
    info.defense = 5
  end
end
