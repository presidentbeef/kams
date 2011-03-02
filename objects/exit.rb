require 'lib/gameobject'

#A generic exit. Add to Rooms to move between them. Don't forget to put an Exit in both rooms, if you want to move between them.
#
#It is best to put the direction in the alternate names of the exit. For example 'e' and 'east' should be included if the exit leads east. This
#also allows for exotic exit types, since the player can always do "go around" and an exit matching "around" would work.
class Exit < GameObject
  #GOID of room the exit leads to.
  attr_accessor :exit_room

  #Creates a new exit. Connects to exit_room if that is provided.
  def initialize(exit_room = nil, *args)
    super(*args)
    @exit_room = exit_room
    @generic = 'exit'
    @article = 'an'
    @alt_names ||= ["[Needs name]"]
  end

  #Returns the name of the room on the other side.
  def peer
    if @exit_room
      room = $manager.find(@exit_room)
      if room.nil?
        "You see only darkness of the deepest black."
      else
        "Squinting slightly, you can see #{room.name}."
      end
    else
      "This exit does not seem to lead anywhere."
    end
  end
end
