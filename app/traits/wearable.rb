#Include this module for objects that are wearable.
#
#Clothing is layered. Higher numbered layers are covered by lower layers. For example:
#
# 0. Accessories/wielded items
# 1. Armor
# 2. Regular clothing
# 3. Underclothing
# 4. Skin/tattoos/scars
#
module Wearable
  def initialize *args
    super
    info.position = :torso
    info.layer = 2
  end

  #Returns position, as a symbol
  #
  #Possible positions (used in Equipment):
  #
  def position
    info.position || nil
  end

  #Returns layer, an Integer
  def layer
    info.layer || 2
  end
end
