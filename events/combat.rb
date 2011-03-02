require 'yaml'

#This is likely to get overhauled one day.
module Combat

  #Keeps track of 'in-flight' combat events.
  class CombatEventTracker

    def initialize
      @events = []
    end

    #Add an event to the list.
    def add event
      @events << event
    end

    #Find an event with the given attributes.
    #
    # find(:action => :slash)
    # find(:player => someone)
    def find args
      @events.find do |e|
        match = true
        args.each do |k,v|
          if e[k] != v
            match = false
            break
          end
        end
        match
      end
    end

    #Same as CombatEventTracker#find, except returns an array of all matches.
    def find_all args
      @events.find_all do |e|
        match = true
        args.each do |k,v|
          if e[k] != v
            match = false
            break
          end
        end
        match
      end
    end

    #Remove event from list.
    def delete event
      @events.delete event
    end

    #Display the events currently in the list nicely.
    def inspect
      @events.map do |e|
        e.to_s
      end.join(", ")
    end
  end

  Events = CombatEventTracker.new

  class << self

    #Attempts to run away during combat.
    def flee(event, player, room)
      dir_exit = room.exit(event[:direction])

      if dir_exit.nil?
        player.output("You cannot go #{event[:direction]}.")
        return
      elsif dir_exit.is_a? Portal
        player.output "You cannot simply go that way."
        return
      elsif dir_exit.can? :open and not dir_exit.open?
        player.output("That exit is closed. Perhaps you should open it?")
        return
      elsif player.prone?
        player.output('You must stand up first.')
        return
      end

      events = Combat.find_events(:target => player)

      if events.empty?
        player.output "What are you trying to flee from?"
        player.info.in_combat = false
        return
      end

      if rand > 0.5
        dir = expand_direction event.direction
        events.each do |e|
          e.action = :flee
          e.type = :Movement
          e.direction = dir
        end
        player.info.fleeing = true
      end

      player.balance = false
      event.to_player = "Heart beating wildly, you attempt to flee from combat."
      event.to_other = "#{player.name} looks about wildly for a way to escape."
      room.out_event event
    end

    #I guess damage calculations should go here.
    #
    #Calls take_damage on the target, outputs the event to the
    #room, then calls the death sequence if necessary.
    def inflict_damage(event, player, room, base)
      target = event.target

      if target.can? :take_damage
        target.take_damage base
      end

      room.out_event event

      if target.info.stats.health and target.info.stats.health <= 0
        death target
      end
    end

    #Goes through death sequence for give player/mobile.
    def death player
      room = $manager.get_object player.container
      player.alive = false

      unless room.nil?
        room.remove player
        room.output player.death_message
      end

      case player
      when Player
        player.output "You vision fills with darkness as you breathe your last breath."
        after 5 do
          defroom = $manager.get_object ServerConfig.start_room
          player.info.stats.health = player.info.stats.max_health
          player.output "Streams of golden light pour down on you as you are restored to life."
          defroom.add player
          player.alive = true
        end
      when Respawns
        corpse = $manager.create_object(Corpse, nil, nil)
        corpse.corpse_of player
        room.add corpse
        player.info.respawn_time = (Time.now.to_i + player.info.respawn_rate)
      else
        log "Don't know how to handle dead #{player}"
      end
    end

    #Check if the player is balanced.
    #Gives message to player if not balanced.
    def balanced? player
      if player.balance
        true
      else
        player.output "You do not have the balance to do that."
        false
      end
    end

    #Checks if the target is valid (alive, etc.)
    #Gives message to player if invalid.
    def valid_target? player, target
      if not target.is_a? GameObject
        player.output "What are you trying to attack?"
        false
      elsif not target.is_a? LivingObject
        player.output "You cannot attack #{target.name}."
        false
      elsif target == player
        player.output "You cannot attack yourself."
        false
      else
        true
      end
    end

    #Checks if player is balanced, not blind, and not prone.
    #Prints message if any of these are not true.
    def ready? player
      if not Combat.balanced? player
        false
      elsif player.blind?
        player.output "You cannot see who you are trying to attack!"
        false
      elsif player.prone?
        player.output "You must stand up first."
        false
      else
        true
      end
    end

    #Finds a target for the given event. Unless suppress_output is true,
    #method will alert player if the target cannot be found.
    def get_target(event, suppress_output = false)
      player = event[:player]
      room = $manager.find player.room
      if event[:target].nil?
        if player.last_target.nil?
          target = nil
        else
          target = room.find(player.last_target)
        end
      else
        target = room.find(event[:target])
      end

      if target.nil?
        player.output "Who are you fighting?" unless suppress_output
        return nil
      elsif not target.can? :alive
        player.output "You cannot do that to #{target.name}." unless suppress_output
        return nil
      elsif not target.alive
        player.output "#{target.name} is no longer living." unless suppress_output
        return nil
      end

      return target
    end

    #Add event to list.
    def add_event event
      Events.add event
    end

    #Remove event from list,
    def delete_event event
      Events.delete event
    end

    #Find events matching the given args.
    def find_events args
      Events.find_all args
    end

    #Add an event for the future. Does Combat#add_event as well.
    #
    #If there are already events which target this player,
    #the event will be attached to those events so it ends
    #at the same time.
    #
    #Otherwise, the event will occur after the given delay.
    def future_event event, delay = 2.5, unit = :sec
      events = Events.find_all(:target => event.player)
      if events.empty?
        after delay, unit, event
      else
        log "Attaching event to #{events[0].object_id}"
        events[0].attach_event event
      end
      Events.add event
    end
  end
end
