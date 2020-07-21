#Mixing in this module will allow any GameObject to react to events.
module Reacts

  def initialize(*args)
    super
    init_reactor
  end

  #Checks if a given object uses the reactions stored in a given file.
  def uses_reaction? file
    @reactions_files.include? file
  end

  # Automatically set up the reactor when we extend an object
  def self.extended(obj)
    obj.init_reactor
  end

  def init_reactor
    @reactor ||= Reactor.new(self)
    @reaction_files ||= Set.new
    @tick_actions ||= TickActions.new
    alert(Event.new(:Generic, :action => :init))
  end

  #Clears out current reactions and loads the ones
  #which have previously been loaded from a file.
  def reload_reactions
    @reactor.clear
    if @reaction_files
      @reaction_files.each do |file|
        load_reactions file
      end
    end
    alert(Event.new(:Generic, :action => :init))
  end

  #Deletes all reactions but does not clear the list of reaction files.
  def unload_reactions
    @reactor.clear if @reactor
    @reaction_files.clear if @reaction_files
  end

  #Loads reactions from a file.
  #
  #Note: This appends them to the existing reactions. To reload,
  #use Mobile#reload_reactions
  def load_reactions file
    @reaction_files ||= Set.new
    @reaction_files << file
    @reactor.load(file)
    alert(Event.new(:Generic, :action => :init))
  end

  #Respond to an event by checking it against registered reactions.
  def alert(event)
    log "Got an alert about #{event}", Logger::Ultimate
    log "I am #{self.goid}", Logger::Ultimate
    reactions = @reactor.react_to(event)
    unless reactions.nil?
      reactions.each do |reaction|
        log "I am reacting...#{reaction.inspect}", Logger::Ultimate
        action = CommandParser.parse(self, reaction)
        unless action.nil?
          log "I am doing an action...", Logger::Ultimate
          changed
          notify_observers(action)
        else
          log "Action did not parse: #{reaction}", Logger::Medium
        end
      end
    else
      log "No Reaction to #{event}", Logger::Ultimate
    end
  end

  #Returns a String representation of the reactions this GameObject has.
  def show_reactions
    if @reactor
      @reactor.list_reactions
    else
      "Reactor is nil"
    end
  end

  #Runs any actions set up on ticks.
  def run
    super
    @tick_actions ||= TickActions.new
    if @tick_actions.length > 0
      @tick_actions.dup.each_with_index do |e, i|
        if e[0] <= 0
          e[1].call
          if e[2]
            @tick_actions[i][0] = e[2]
          else
            @tick_actions.delete i
          end
        else
          e[0] -= 1
        end
      end
    end
  end

  private

  #Determines if the object of an event is this object.
  #
  #Mainly for use in reaction scripts.
  def object_is_me? event
    event[:target] == self
  end

  #Parses command and creates a new event.
  #Unless delay is true, the event is added to to event handler.
  def act command, delay = false
    event = CommandParser.parse(self, command)
    return false if event.nil? #failed to parse

    add_event event unless delay
    event
  end

  #Does "emote ..."
  def emote string
    act "emote #{string}"
  end

  #Does "say ..."
  def say output
    act "say #{output}"
  end

  #Does "sayto target ..."
  def sayto target, output
    target = target.name if target.is_a? GameObject
    act "sayto #{target} #{output}"
  end

  #Moves in the given direction
  def go direction
    act "go #{direction}"
  end

  #Calls Manager::get_object
  def get_object goid
    $manager.get_object goid
  end

  #Calls Manager::find
  def find name, container = nil
    $manager.find name, container
  end

  #Randomly performs an act from the given list
  def random_act *acts
    act acts[rand(acts.length)]
  end

  #Do the given act with the given probability (between 0 and 1)
  def with_prob probability, action = ""
    if rand < probability
      if block_given?
        yield
      else
        act action
      end
      true
    else
      false
    end
  end

  #Moves randomly, but only within the same area
  def random_move probability = 1
    return if rand > probability

    room = get_object self.container
    area = room.area
    unless room.nil?
      exits = room.exits.select do |e|
        other_side = get_object e.exit_room
        not other_side.nil? and other_side.area == area
      end.map {|e| e.alt_names[0] }

      if exits.respond_to? :shuffle
        exits = exits.shuffle
      else
        exits = exits.sort_by { rand }
      end

      go exits[rand(exits.length)]
    end
  end

  #Creates an object and puts it in the creator's inventory if it has one
  def make_object klass
    obj = $manager.make_object klass
    inventory << obj if self.respond_to? :inventory
    obj
  end

  #Deletes an object
  def delete_object object
    $manager.delete object
  end

  #Checks if the given phrase was said in the event.
  def said? event, phrase
    if event[:phrase]
      event[:phrase].downcase.include? phrase.downcase
    else
      false
    end
  end

  #After the given number of ticks, execute the given block.
  def after_ticks ticks, &block
    @tick_actions << [ticks.to_i, block, false]
  end

  #After every number of ticks, execute the given block.
  def every_ticks ticks, &block
    @tick_actions << [ticks.to_i, block, ticks.to_i]
  end

  #Turns an array of actions into a chained sequence of events.
  #This method returns the first event in the sequence, but does not
  #add it to the event queue.
  #
  #Options should be passed in as a hash.
  #
  #  :initial_delay  -  delay before first action (Default: 0 seconds)
  #  :delay  -  delay between actions (Default: 0 seconds)
  #  :loop   -  true to repeat sequence infinitely (Default: false)
  def action_sequence sequence, options = {}
    delay = options[:delay] || 0
    continuous_loop = false || options[:loop]

    first_step = sequence.shift

    if first_step.is_a? String
      first_step = CommandParser.parse self, sequence.shift
    end

    last_step = first_step

    if delay > 0
      sequence.each do |next_step|
        next_step = CommandParser.parse self, next_step if next_step.is_a? String
        last_step.attach_event CommandParser.future_event self, delay, next_step
        last_step = next_step
      end
    else
      sequence.each do |next_step|
        next_step = CommandParser.parse self, next_step if next_step.is_a? String
        last_step.attach_event next_step
        last_step = next_step
      end
    end

    if options[:initial_delay]
      first_step = CommandParser.future_event self, options[:initial_delay], first_step
    end

    if continuous_loop
      last_step.attach_event first_step
    end

    first_step
  end

  def teleport item, destination, options = {}
    event = Event.new :Mobiles, {:action => :teleport, :player => self, :object => item, :in => destination}.merge(options)
    add_event event
  end

  def follow object, message = nil
    unless object.is_a? GameObject
      object = $manager.find event[:object]
    end

    if object.nil?
      self.output "Cannot follow that."
      return
    end

    self.info.following = object.goid
    object.info.followers ||= Set.new
    object.info.followers << self.goid

    if message
      object.output message unless message.empty?
    else
      object.output "#{self.name.capitalize} begins to follow you."
    end
  end

  def unfollow object, message = nil
    if self.info.following.nil?
      self.output "Not following anyone"
      return
    elsif not object.is_a? GameObject
      object = $manager.find object
    end

    if object.nil?
      self.output "Cannot follow that."
      return
    end

    self.info.following = nil
    object.info.followers.delete self.goid

    $stderr.puts "GOT AWAY WITH IT"

    if message
      object.output message unless message.empty?
    else
      object.output "#{self.name.capitalize} is no longer following you."
    end
  end

end

class TickActions
  def initialize
    @tick_actions = []
  end

  def length
    @tick_actions.length
  end

  def each_with_index &block
    @tick_actions.each_with_index &block
  end

  def delete item
    @tick_actions.delete item
  end

  def << obj
    @tick_actions << obj
  end

  def marshal_dump
    ""
  end

  def marshal_load *args
    @tick_actions = []
  end
end
