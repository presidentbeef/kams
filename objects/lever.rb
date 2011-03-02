require 'objects/container'
#This is an object to test out the 'custom actions' dealie
#
#In general, built-in actions will be fast and therefore more efficient,
#but if you want to have a custom action which is only used once or twice,
#or has different semantics to different objects, this would be the way to go,
#I think.
class Lever < GameObject
  def initialize(*args)
    super(*args)
    @name = 'lever'
    @generic = 'lever'
    @short_desc = 'lever'
    @long_desc = 'A lever, about 2 feet long with a grip situated near the top, just begging to be pulled.'
    @actions << "pull"
  end
end
