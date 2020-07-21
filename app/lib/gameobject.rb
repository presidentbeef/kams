require 'util/log'
require 'objects/inventory'
require 'traits/pronoun'
require 'util/guid'
require 'observer'
require 'lib/info'

#Base class for all game objects, including players. Should be subclassed to do anything useful.
class GameObject
  include Observable
  include Pronoun

  attr_reader :short_desc, :game_object_id, :alt_names, :generic, :article, :sex, :show_in_look, :actions, :balance, :admin
  attr_accessor :container, :show_in_look, :actions, :pose, :visible, :comment, :movable, :quantity, :info
  attr_writer :plural
  alias :room :container
  alias :can? :respond_to?
  alias :goid :game_object_id

  #Creates a new GameObject. Most of this long list of parameters is simply ignored at creation time,
  #because they can all be set later.
  def initialize(game_object_id = nil, container = nil, name = "", alt_names = Array.new, short_desc = "Nothing interesting here.", long_desc = "", generic = "", sex = "n", article = "a")
    @info = Info.new
    #Where the object is
    @container = container
    #The name of the object
    @name = name
    #Alternate names for the object
    @alt_names = alt_names
    #The short description of the object
    @short_desc = short_desc
    #The long, detailed description of the object
    @long_desc = long_desc
    #The generic description of the object (e.g., 'spoon')
    @generic = generic
    #The sex of the object
    @sex = sex
    #The article of the object ('a','an',etc)
    @article = article
    @visible = true
    #This is tricky. If @show_in_look is something
    #other than false (or nil), then the object will
    #not show up in the list of objects, but rather this
    #description (in @show_in_look) will be shown as
    #part of the room's description.
    @show_in_look = false
    #How many? I dunno if this is useful yet.
    @quantity = 1
    #If this object can be picked up/moved
    @movable = false
    #Pose
    @pose = nil
    #Busy (running update)
    @busy = false
    #Plural
    @plural = nil
    #Comments for builders/coders/etc
    @comment = nil
    #Grab a new goid if one was not provided
    if game_object_id.nil?
      begin
        @game_object_id = Guid.new.to_s
      end while $manager.existing_goid? @game_object_id
    else
      @game_object_id = game_object_id
    end
    @plural = nil
    @actions = Set.new
    @admin = false
  end

  #Outputs a string to the object.
  def output(string, suppress_prompt = false)
    #fill in subclasses
  end

  #Just calls #alert.
  def out_event(event)
    alert(event)
  end

  #Generic 'tick' function called to update the object's state.
  #
  #Calls GameObject#run , which is where any "thinking" or decision
  #logic should go.
  def update
    return if @busy
    @busy = true
    if self.is_a? Reacts
      self.alert(Event.new(:Generic, :action => :tick))
    end
    run
    @busy = false
  end

  #Checks if the GameObject is busy in the GameObject#update method.
  #This prevents the update method from being called more than once
  #at a time.
  def busy?
    @busy
  end

  #Returns plural form of object's name.
  def plural
    return @plural if @plural
    if @generic
      "#{@generic}s"
    elsif @name
      "#{@names}s"
    else
      "unkowns"
    end
  end

  #Run any logic you need (thinking).
  #
  #To be implemented in the subclasses
  def run
  end

  #Just a way to put an event into the system, nothing more, nothing less.
  def add_event(event)
    changed
    notify_observers(event)
  end

  #Basically, this is where hooks for events would go.
  def alert(event)
  end

  #This is implemented so that we can just ignore calls that don't apply.
  def method_missing(*args)
    log "#{@name} - #{@game_object_id} is ignoring #{args.inspect}"
    log "Consider user #can? instead"
    log caller
    #I don't do nuttin' if I have no reaction to that message
    return nil
  end

  #Compares com_val to game_object_id, then to name, then to alternate names.
  def == comp_val
    if comp_val.nil?
      return false
    elsif comp_val == @game_object_id
      return true
    elsif comp_val.is_a?(String) and comp_val.downcase == @name.downcase
      return true
    elsif comp_val.is_a?(String) and @alt_names.include?(comp_val)
      return true
    elsif comp_val.is_a? Class and self.class == comp_val
      return true
    else
      false
    end
  end

  #Outputs the object and the object name.
  def to_s
    "#{self.class}(#{@name}|#{@game_object_id})"
  end

  #Sets the long description of the object.
  def long_desc= desc
    @long_desc = desc
  end

  #This is the long description of the object. If there is no long
  #description, it just shows the short description.
  def long_desc
    if @long_desc == ""
      @short_desc
    else
      @long_desc
    end
  end

  #Determines if the object can move.
  def can_move?
    @movable
  end

  #Message when entering from the given direction.
  #If info.entrance_message has not been set and no message is provided, returns a generic movement message.
  #
  #Otherwise, either pass in a message or else info.entrance_message can be used to create custom messages.
  #
  #Use !direction and !name in place of the direction and name.
  #
  #For example, let's say you had a mobile whose generic was 'large bird':
  # "!name flies in from the !direction." => "A large bird flies in from the west."
  #
  #If something more complicated is required, override this method in a subclass.
  def entrance_message direction, message = nil
    if info.entrance_message and not message
      message = info.entrance_message
    end

    case direction
    when "up"
      direction = "up above"
    when "down"
      direction = "below"
    when "in"
      direction = "inside"
    when "out"
      direction = "outside"
    else
      direction = "the " << direction
    end

    if message
      message.gsub(/!direction/, direction).gsub(/!name/, self.name)
    else
      "#{self.name.capitalize} enters from #{direction}."
    end
  end

  #Message when leaving in the given direction. Works the same way as #entrance_message
  def exit_message direction, message = nil
    if info.exit_message and not message
      message = info.exit_message
    end

    case direction
    when "up"
      direction = "go up"
    when "down"
      direction = "go down"
    when "in"
      direction = "go inside"
    when "out"
      direction = "go outside"
    else
      direction = "the " << direction
    end

    if message
      message.gsub(/!direction/, direction).gsub(/!name/, self.name)
    else
      "#{self.name.capitalize} leaves to #{direction}."
    end
  end

  #Returns the name of the object, or, if the name is empty,
  #the article + the generic name of the object.
  def name
    if @name == ""
      @article + " " + @generic
    else
      @name
    end
  end

end

