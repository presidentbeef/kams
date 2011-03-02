require 'lib/gameobject'
class Armor < GameObject
  include Wearable

  attr_accessor :position, :slash_def, :pierce_def, :blunt_def, :frost_def, :energy_def

  def initialize(*args)
    super
    @generic = "armor"
    @article = "a suit of"
    @movable = true
    @condition = 100
    info.layer = 1
    info.position = :torso
  end
end
