#Use this module for objects that can be opened and possibly locked.
#
#This is an older module and the API may be revised in the future.
module Openable
  attr_accessor :keys, :lockable

  def initialize(*args)
    super(*args)

    @locked = false
    @openable = true
    @open = false
    @lockable = false
    @keys = []
  end

  #Overrides look_inside methods to first check if an object is open prior to
  #looking inside.
  def Openable.included(klass)
    if klass.respond_to? :look_inside
      klass.instance_eval { alias_method :old_look_inside, :look_inside }
      klass.send(:define_method, :look_inside) do |event|
        if @open
          old_look_inside(event)
        else
          event[:player].output("You'll need to open it first.")
        end
      end
    end
  end

  #Opens container, if possible. Takes care of notifying the player of the result.
  def open(event)
    player = event[:player]

    if @locked
      player.output("The #{@generic} is locked.")
    elsif @open
      player.output("The #{@generic} is already open, silly.")
    else
      @open = true
      room = $manager.find(player.room, nil)

      if @name.empty?
        player.output "You open #@article #@generic."
        room.output "#{player.name} opens #@article #@generic.", player
      else
        player.output "You open #@name."
        room.output "#{player.name} opens #@name.", player
      end
    end
  end

  #Closes container, if possible. Takes care of notifying the player of the result.
  def close(event)
    player = event[:player]

    if not @open
      player.output("The #{@generic} is already closed, silly.")
    else
      @open = false
      room = $manager.find(player.room, nil)

      if @name.empty?
        player.output "You close #@article #@generic."
        room.output "#{player.name} closes #@article #@generic.", player
      else
        player.output "You close #@name."
        room.output "#{player.name} closes #@name.", player
      end
    end
  end

  #Locks the object with the key. Returns true if successful, false otherwise.
  #
  #In this case the key is the GOID of a key.
  def lock(key, admin = false)
    if @lockable and not @locked and (@keys.include? key or admin)
      @locked = true

      if self.can? :connected_to
        other = $manager.find self.connected_to
        other.lock(key, admin) if other.can? :lock
      end

      true
    else
      false
    end
  end

  #Unlocks the object with the key. Returns true if successful, false otherwise.
  #
  #In this case the key is the GOID of a key.
  def unlock(key, admin = false)
    if @lockable and @locked and (@keys.include? key or admin)
      @locked = false

      if self.can? :connected_to
        other = $manager.find self.connected_to
        other.unlock(key, admin) if other.can? :lock
      end

      true
    else
      false
    end
  end

  #This is kind of a retarded method. Always returns true.
  def openable?
    true
  end

  #True if the object can be locked.
  def lockable?
    @lockable
  end

  #True if the object is locked.
  def locked?
    @locked
  end

  #True if the object is open.
  def open?
    @open
  end

  #True if the object is closed.
  def closed?
    not @open
  end
end
