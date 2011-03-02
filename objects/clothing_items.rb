require 'traits/wearable'
require'lib/gameobject'

class GenericClothing < GameObject
  include Wearable

  def initialize(*args)
    super
    @movable = true
    info.layer = 2
  end

end

class Shirt < GenericClothing
  include Wearable

  def initialize(*args)
    super
    info.position = :torso
    @name = 'a nice shirt'
    @generic = 'shirt'
  end
end

class Underwear < GenericClothing
  include Wearable

  def initialize(*args)
    super
    info.position = :legs
    info.layer = 3
    @article = 'a pair of'
    @generic = 'briefs'
  end
end

class Pants < GenericClothing
  include Wearable

  def initialize(*args)
    super
    info.position = :legs
    @article = 'a pair of'
    @generic = 'pants'
    @alt_names = ["pants"]
  end
end

class Shoes < GenericClothing
  include Wearable

  def initialize(*args)
    super
    info.position = :feet
    @article = 'a pair of'
    @generic = 'normal shoes'
  end
end

class Glove < GenericClothing
  include Wearable

  def initialize(*args)
    super
    info.position = :hand
    @generic = 'leather gloves'
  end
end

class Necklace < GenericClothing
  include Wearable

  def initialize(*args)
    super
    info.position = :neck
    info.layer = 0
    @generic = 'silver necklace'
  end
end

class Belt < GenericClothing
  include Wearable

  def initialize(*args)
    super
    info.position = :waist
    info.layer = 0
    @generic = 'belt'
  end
end

class Breastplate < GenericClothing
  include Wearable

  def initialize(*args)
    super
    info.position = :torso
    info.layer = 1
    @generic = 'breastplate'
  end
end

