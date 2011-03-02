require 'traits/openable'
require 'objects/exit'

#A...door. A lockable door.
class Door < Exit
  include Openable
  attr_reader :connected_to

  def initialize(exit_room = nil, lockable = true, *args)
    super(exit_room, *args)

    @connected_to = nil
    @lockable = lockable
    @generic = "door"
    @keys = []
    @article = "a"
  end

  #Returns true if the door is connected to another door. This is really vital for
  #doors to function correctly.
  def connected?
    !!@connected_to
  end

  #Method called when the other side of the door opens.
  def other_side_opened
    room = $manager.find @container
    @open = true
    room.output "The #{@generic} opens."
  end

  #Method called when the other side of the door closes.
  def other_side_closed
    room = $manager.find @container
    @open = false
    room.output "The #{@generic} closes."
  end

  #Opens the door.
  def open(event)
    currently_open = @open

    if @connected_to
      super

      #The door was opened
      if currently_open != @open
        other_side = $manager.find @connected_to
        other_side.other_side_opened
      end
    else
      super
    end
  end

  #Closes the door.
  def close(event)
    currently_open = @open

    if @connected_to
      super

      #The door was closed
      if currently_open != @open
        other_side = $manager.find @connected_to
        other_side.other_side_closed
      end
    else
      super
    end
  end

  #Connects this door to another door so it works correctly.
  #Accepts either a Door or a String. If door is a Door, then it automatically connects the other door to itself.
  #Otherwise, you have to call connect_to for each Door. If the other Door is already connected, that connection shall remain.
  #If you are not careful (or if you intend), this could cause strange issues.
  def connect_to(door)
    if door.is_a? Door
      @connected_to = door.game_object_id
      door.connect_to(self) if not door.connected?
      if door.open?
        @open = true
      else
        @open = false
      end
    else
      @connected_to = door
    end
  end
end
