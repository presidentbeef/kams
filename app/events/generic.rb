require 'lib/issues'

#Contains all the generic commands
module Generic
  class << self

    #Shows the inventory of the player.
    def show_inventory(event, player, room)
      player.output(player.show_inventory)
    end

    #Gets (or takes) an object and puts it in the player's inventory.
    def get(event, player, room)

      if event[:from].nil?
        object = $manager.find(event[:object], room)

        if object.nil?
          player.output("There is no #{event[:object]} to take.")
          return
        elsif not object.movable
          player.output("You cannot take #{object.name}.")
          return
        elsif player.inventory.full?
          player.output("You cannot hold any more objects.")
          return
        end

        room.remove(object)
        object.container = player.goid
        player.inventory << object

        event[:to_player] = "You take #{object.name}."
        event[:to_other] = "#{player.name} takes #{object.name}."
        room.out_event(event)
      else
        from = event[:from]
        container = $manager.find(from, room)
        player.inventory.find(from) if container.nil?

        if container.nil?
          player.output("There is no #{from}.")
          return
        elsif not container.is_a? Container
          player.output("Not sure how to do that.")
          return
        elsif container.can? :open and container.closed?
          player.output("You will need to open it first.")
          return
        end

        object = $manager.find(event[:object], container)

        if object.nil?
          player.output("There is no #{event[:object]} in the #{container.name}.")
          return
        elsif not object.movable
          player.output("You cannot take the #{object.name}.")
          return
        elsif player.inventory.full?
          player.output("You cannot hold any more objects.")
          return
        end

        container.remove(object)
        player.inventory.add(object)

        event[:to_player] = "You take #{object.name} from #{container.name}."
        event[:to_other] = "#{player.name} takes #{object.name} from #{container.name}."
        room.out_event(event)
      end
    end

    #Gives an item to someone else.
    def give(event, player, room)
      item = player.inventory.find(event[:item])

      if item.nil?
        if response = player.equipment.worn_or_wielded?(event[:item])
          player.output response
        else
          player.output "You do not seem to have a #{event[:item]} to give away."
        end

        return
      end

      receiver = $manager.find(event[:to], room)

      if receiver.nil?
        player.output("There is no #{event[:to]}.")
        return
      elsif not receiver.is_a? Player and not receiver.is_a? Mobile
        player.output("You cannot give anything to #{receiver.name}.")
        return
      end

      player.inventory.remove(item)
      receiver.inventory.add(item)

      event[:target] = receiver
      event[:to_player] = "You give #{item.name} to #{receiver.name}."
      event[:to_target] = "#{player.name} gives you #{item.name}."
      event[:to_other] = "#{player.name} gives #{item.name} to #{receiver.name}."

      room.out_event(event)
    end

    #Drops an item from the player's inventory into the room.
    def drop(event, player, room)
      object = player.inventory.find(event[:object])

      if object.nil?
        if response = player.equipment.worn_or_wielded?(event[:object])
          player.output response
        else
          player.output "You have no #{event[:object]} to drop."
        end

        return
      end

      player.inventory.remove(object)

      object.container = room.goid
      room.add(object)

      event[:to_player] = "You drop #{object.name}."
      event[:to_other] = "#{player.name} drops #{object.name}."
      event[:to_blind_other] = "You hear something hit the ground."
      room.out_event(event)
    end

    #Look
    def look(event, player, room)
      if player.blind?
        player.output "You cannot see while you are blind."
      else
        if event[:at]
          object = room if event[:at] == "here"
          object = object || player.search_inv(event[:at]) || room.find(event[:at])

          if object.nil?
            player.output("Look at what, again?")
            return
          end

          if object.is_a? Exit
            player.output object.peer
          elsif object.is_a? Room
            player.output("You are indoors.", true) if object.info.terrain.indoors
            player.output("You are underwater.", true) if object.info.terrain.underwater
            player.output("You are swimming.", true) if object.info.terrain.water

            player.output "You are in a place called #{room.name} in #{room.area ? room.area.name : "an unknown area"}.", true
            if room.area
              player.output "The area is generally #{describe_area(room.area)} and this spot is #{describe_area(room)}."
            elsif room.info.terrain.room_type
              player.output "Where you are standing is considered to be #{describe_area(room)}."
            else
              player.output "You are unsure about anything else concerning the area."
            end
          elsif player == object
            player.output "You look over yourself and see:\n#{player.instance_variable_get("@long_desc")}", true
            player.output object.show_inventory
          else
            player.output object.long_desc
          end
        elsif event[:in]
          object = room.find(event[:in])
          object = player.inventory.find(event[:in]) if object.nil?

          if object.nil?
            player.output("Look inside what?")
          elsif not object.can? :look_inside
            player.output("You cannot look inside that.")
          else
            object.look_inside(event)
          end
        else
          if not room.nil?
            player.output(room.look(player))
          else
            player.output "Nothing to look at."
          end
        end
      end
    end

    #Open anything openable
    def open(event, player, room)
      object = expand_direction(event[:object])
      object = player.search_inv(object) || $manager.find(object, room)

      if object.nil?
        player.output("Open what?")
      elsif not object.can? :open
        player.output("You cannot open #{object.name}.")
      else
        object.open(event)
      end
    end

    #Close things...that are open
    def close(event, player, room)
      object = expand_direction(event[:object])
      object = player.search_inv(object) || $manager.find(object, room)

      if object.nil?
        player.output("Close what?")
      elsif not object.can? :open
        player.output("You cannot close #{object.name}.")
      else
        object.close(event)
      end
    end

    #Puts an object into a container.
    def put(event, player, room)

      item = player.inventory.find(event[:item])

      if item.nil?
        if response = player.equipment.worn_or_wielded?(event[:item])
          player.output response
        else
          player.output "You do not seem to have a #{event[:item]}."
        end

        return
      end

      container = player.search_inv(event[:container]) || $manager.find(event[:container], room)

      if container.nil?
        player.output("There is no #{event[:container]} in which to put #{item.name}.")
        return
      elsif not container.is_a? Container
        player.output("You cannot put anything in #{container.name}.")
        return
      elsif container.can? :open and container.closed?
        player.output("You need to open #{container.name} first.")
        return
      end

      player.inventory.remove(item)
      container.add(item)

      event[:to_player] = "You put #{item.name} in #{container.name}."
      event[:to_other] = "#{player.name} puts #{item.name} in #{container.name}"

      room.out_event(event)
    end

    #Moves to another room.
    def move(event, player, room)
      exit = room.exit(event[:direction])

      if exit.nil?
        player.output("You cannot go #{event[:direction]}.")
        return
      elsif exit.can? :open and not exit.open?
        player.output("That exit is closed. Perhaps you should open it?")
        return
      end

      new_room = $manager.find(exit.exit_room)

      if new_room.nil?
        player.output("That exit #{exit.name} leads into the void.")
        return
      end

      room.remove(player)
      new_room.add(player)
      player.container = new_room.game_object_id
      event[:to_player] = "You move #{event[:direction]}."
      event[:to_other] = "#{player.name} leaves #{event[:direction]}."
      event[:to_blind_other] = "You hear someone leave."

      room.out_event(event)
    end

    #Display help.
    def help(event, player, room)
      topic = event[:object].strip.downcase
      if event[:action] == :ahelp
        path = "help/admin/"
      else
        path = "help/"
      end

      if topic.include? 'topics' or topic == ''
        player.output('Help topics available:', true)
        topics = []
        Dir.glob("#{path}*.help").sort.each do |filename|
          topics << filename[/#{path}(.*)\.help/, 1].upcase
        end

        player.output(topics)
        return
      end

      help_item = "#{path}#{topic}.help"

      if File.exist? help_item
        player.output(IO.read(help_item))
      else
        player.output("No help found for #{topic}.")
      end
    end

    #Lock something.
    def lock(event, player, room)
      object = player.search_inv(event[:object]) || room.find(event[:object])

      if object.nil?
        player.output('Lock what?')
        return
      elsif not object.can? :lock or not object.lockable?
        player.output('That object cannot be locked.')
        return
      elsif object.locked?
        player.output("#{object.name} is already locked.")
        return
      end

      has_key = false
      object.keys.each do |key|
        if player.inventory.include? key
          has_key = key
          break
        end
      end

      if has_key or player.admin
        status = object.lock(has_key, player.admin)
        if status
          event[:to_player] = "You lock #{object.name}."
          event[:to_other] = "#{player.name} locks #{object.name}."
          event[:to_blind_other] = "You hear the click of a lock."

          room.out_event(event)

          if object.is_a? Door and object.connected?
            other_side = $manager.find object.connected_to
            other_side.lock(has_key)
            other_room = $manager.find other_side.container
            o_event = event.dup
            event[:to_other] = "#{other_side.name} locks from the other side."
            event[:to_blind_other] = "You hear the click of a lock."
            other_room.out_event(event)
          end
        else
          player.output("You are unable to lock that #{object.name}.")
        end
      else
        player.output("You do not have the key to that #{object.name}.")
      end
    end

    #Unlock something.
    def unlock(event, player, room)
      object = player.search_inv(event[:object]) || room.find(event[:object])

      if object.nil?
        player.output("Unlock what? #{event[:object]}?")
        return
      elsif not object.can? :unlock or not object.lockable?
        player.output('That object cannot be unlocked.')
        return
      elsif not object.locked?
        player.output("#{object.name} is already unlocked.")
        return
      end

      has_key = false
      object.keys.each do |key|
        if player.inventory.include? key
          has_key = key
          break
        end
      end

      if has_key or player.admin
        status = object.unlock(has_key, player.admin)
        if status
          event[:to_player] = "You unlock #{object.name}."
          event[:to_other] = "#{player.name} unlocks #{object.name}."
          event[:to_blind_other] = "You hear the clunk of a lock."

          room.out_event(event)

          if object.is_a? Door and object.connected?
            other_side = $manager.find object.connected_to
            other_side.unlock(has_key)
            other_room = $manager.find other_side.container
            o_event = event.dup
            event[:to_other] = "#{other_side.name} unlocks from the other side."
            event[:to_blind_other] = "You hear the click of a lock."
            other_room.out_event(event)
          end

          return
        else
          player.output("You are unable to unlock #{object.name}.")
          return
        end
      else
        player.output("You do not have the key to #{object.name}.")
        return
      end
    end

    #Display health.
    def health(event, player, room)
      player.output "You are #{player.health}."
    end

    #Display hunger.
    def satiety(event, player, room)
      player.output "You are #{player.satiety}."
    end

    #Display status.
    def status(event, player, room)
      player.output("You are #{player.health}.", true)
      player.output("You are feeling #{player.satiety}.", true)
      player.output "You are currently #{player.pose || 'standing up'}."
    end

    #Fill something.
    def fill(event, player, room)
      object = player.search_inv(event[:object]) || room.find(event[:object])
      from = player.search_inv(event[:from]) || room.find(event[:from])

      if object.nil?
        player.output("What would you like to fill?")
        return
      elsif not object.is_a? LiquidContainer
        player.output("You cannot fill #{object.name} with liquids.")
        return
      elsif from.nil?
        player.output "There isn't any #{event[:from]} around here."
        return
      elsif not from.is_a? LiquidContainer
        player.output "You cannot fill #{object.name} from #{from.name}."
        return
      elsif from.empty?
        player.output "That #{object.generic} is empty."
        return
      elsif object.full?
        player.output("That #{object.generic} is full.")
        return
      elsif object == from
        player.output "Quickly flipping #{object.name} upside-down then upright again, you manage to fill it from itself."
        return
      end

    end

    #Display time.
    def time(event, player, room)
      player.output $manager.time
    end

    #Display date.
    def date(event, player, room)
      player.output $manager.date
    end

    #Show who is in the game.
    def who(event, player, room)
      players = $manager.find_all("class", Player)
      output = ["The following people are visiting Ahln:"]
      players.sort_by {player.name}.each do |playa|
        room = $manager.find playa.container
        output << "#{playa.name} - #{room.name if room}"
      end

      player.output output
    end

    #Display more paginated text.
    def more(event, player, room)
      player.more
    end

    #Delete your player.
    def deleteme(event, player, room)
      if event[:password]
        if $manager.check_password(player.name, event[:password])
          player.output "This character #{player.name} will no longer exist."
          player.quit
          $manager.delete_player(player.name)
        else
          player.output "That password is incorrect. You are allowed to continue existing."
        end
      else
        player.output "To confirm your deletion, please enter your password:"
        player.io.echo_off
        player.expect do |password|
          player.io.echo_on
          event[:password] = password
          Generic.deleteme(event, player, room)
        end
      end
    end

    #Write something.
    def write(event, player, room)
      object = player.search_inv(event[:target])

      if object.nil?
        player.output "What do you wish to write on?"
        return
      end

      if not object.info.writable
        player.output "You cannot write on #{object.name}."
        return
      end

      player.output "You begin to write on #{object.name}."

      player.editor(object.readable_text || [], 100) do |data|
        unless data.nil?
          object.readable_text = data
        end
        player.output "You finish your writing."
      end
    end

    def taste(event, player, room)

      object = player.search_inv(event[:target]) || room.find(event[:target])

      if object == player or event[:target] == "me"
        player.output "You covertly lick yourself.\nHmm, not bad."
        return
      elsif object.nil?
        player.output "What would you like to taste?"
        return
      end

      event[:target] = object
      event[:to_player] = "Sticking your tongue out hesitantly, you taste #{object.name}. "
      if object.info.taste.nil? or object.info.taste == ""
        event[:to_player] << "#{object.pronoun.capitalize} does not taste that great, but has no particular flavor."
      else
        event[:to_player] << object.info.taste
      end
      event[:to_target] = "#{player.name} licks you, apparently in an attempt to find out your flavor."
      event[:to_other] = "#{player.name} hesitantly sticks out #{player.pronoun(:possessive)} tongue and licks #{object.name}."
      room.out_event event
    end

    def smell(event, player, room)
      if event[:target].nil?
        if room.info.smell
          event[:to_player] = "You sniff the air. #{room.info.smell}."
        else
          event[:to_player] = "You sniff the air, but detect no unusual aromas."
        end
        event[:to_other] = "#{player.name} sniffs the air."
        room.out_event event
        return
      end

      object = player.search_inv(event[:target]) || room.find(event[:target])

      if object == player or event[:target] == "me"
        event[:target] = player
        event[:to_player] = "You cautiously sniff your armpits. "
        if rand > 0.6
          event[:to_player] << "Your head snaps back from the revolting stench coming from beneath your arms."
          event[:to_other] = "#{player.name} sniffs #{player.pronoun(:possessive)} armpits, then recoils in horror."
        else
          event[:to_player] << "Meh, not too bad."
          event[:to_other] = "#{player.name} sniffs #{player.pronoun(:possessive)} armpits, then shrugs, apparently unconcerned with #{player.pronoun(:possessive)} current smell."
        end
        room.out_event event
        return
      elsif object.nil?
        player.output "What are you trying to smell?"
        return
      end

      event[:target] = object
      event[:to_player] = "Leaning in slightly, you sniff #{object.name}. "
      if object.info.smell.nil? or object.info.smell == ""
        event[:to_player] << "#{object.pronoun.capitalize} has no particular aroma."
      else
        event[:to_player] << object.info.smell
      end
      event[:to_target] = "#{player.name} sniffs you curiously."
      event[:to_other] = "#{player.name} thrusts #{player.pronoun(:possessive)} nose at #{object.name} and sniffs."
      room.out_event event
    end

    def listen(event, player, room)
      if event[:target].nil?
        event[:target] = room
        if room.info.sound
          event[:to_player] = "You listen carefully. #{room.info.sound}."
        else
          event[:to_player] = "You listen carefully but hear nothing unusual."
        end
        event[:to_other] = "A look of concentration forms on #{player.name}'s face as #{player.pronoun} listens intently."
        room.out_event event
        return
      end

      object = player.search_inv(event[:target]) || room.find(event[:target])

      if object == player or event[:target] == "me"
        player.output "Listening quietly, you can faintly hear your pulse."
        return
      elsif object.nil?
        player.output "What would you like to listen to?"
        return
      end

      event[:target] = object
      event[:to_player] = "You bend your head towards #{object.name}. "
      if object.info.sound.nil? or object.info.sound == ""
        event[:to_player] << "#{object.pronoun.capitalize} emits no unusual sounds."
      else
        event[:to_player] << object.info.sound
      end
      event[:to_target] = "#{player.name} listens to you carefully."
      event[:to_other] = "#{player.name} bends #{player.pronoun(:possessive)} head towards #{object.name} and listens."
      room.out_event event
    end

    def feel(event, player, room)
      object = player.search_inv(event[:target]) || room.find(event[:target])

      if object == player or event[:target] == "me"
        player.output "You feel fine."
        return
      elsif object.nil?
        player.output "What would you like to feel?"
        return
      end

      event[:target] = object
      event[:to_player] = "You reach out your hand and gingerly feel #{object.name}. "
      if object.info.texture.nil? or object.info.texture == ""
        event[:to_player] << "#{object.pronoun(:possessive).capitalize} texture is what you would expect."
      else
        event[:to_player] << object.info.texture
      end
      event[:to_target] = "#{player.name} reaches out a hand and gingerly touches you."
      event[:to_other] = "#{player.name} reaches out #{player.pronoun(:possessive)} hand and touches #{object.name}."
      room.out_event event
    end

    def issue(event, player, room)
      case event[:option]
      when "new"
        issue = Issues.add_issue event[:itype], player.name, event[:value]
        player.output "Thank you for submitting #{event[:itype]} ##{issue[:id]}."
      when "add"
        if not event[:issue_id]
          player.output "Please specify a #{event[:itype]} number."
        else
          denied = Issues.check_access event[:itype], event[:issue_id], player
          if denied
            player.output denied
          else
            player.output Issues.append_issue(event[:itype], event[:issue_id], player.name, event[:value])
          end
        end
      when "del"
        if not event[:issue_id]
          player.output "Please specify a #{event[:itype]} number."
        else
          denied = Issues.check_access event[:itype], event[:issue_id], player
          if denied
            player.output denied
          else
            player.output Issues.delete_issue(event[:itype], event[:issue_id])
          end
        end
      when "list"
        if player.admin
          list = Issues.list_issues event[:itype]
        else
          list = Issues.list_issues event[:itype], player.name
        end
        if list.empty?
          player.output "No #{event[:itype]}s to list."
        else
          player.output list
        end
      when "show"
        if not event[:issue_id]
          player.output "Please specify a #{event[:itype]} number."
        else
          denied = Issues.check_access event[:itype], event[:issue_id], player
          if denied
            player.output denied
          else
            player.output Issues.show_issue(event[:itype], event[:issue_id])
          end
        end
      when "status"
        if not player.admin
          player.output "Only administrators may change a #{event[:itype]}'s status."
        elsif not event[:issue_id]
          player.output "Please specify a #{event[:itype]} number."
        else
          player.output Issues.set_status(event[:itype], event[:issue_id], player.name, event[:value])
        end

      end
    end

    def quit(event, player, room)
      $manager.drop_player player
    end

    private

    #Describe an area.
    def describe_area(object)

      if object.is_a? Room
        case object.info.terrain.room_type
        when nil
          "uncertain"
        when :urban
          "urban"
        when :road
          "a road"
        when :forest
            "a forest"
        when :desert
          "a sandy desert"
        when :grassland
          "part of the grasslands"
        when :tundra
          "a chilly tundra"
        when :lake
          "in a lake"
        when :pond
          "in a pond"
        when :river
          "in a flowing river"
        when :bog
          "in a murky bog"
        when :marsh
          "in a wet marsh"
        when :swamp
          "in a foggy swamp"
        when :garden
          "a garden"
        else
          object.info.terrain.room_type.to_s
        end

      elsif object.is_a? Area
        case object.info.terrain.area_type
        when  nil
          "unknown"
        when :urban
          "urban"
        when :road
          "roadways"
        when :forest
          "forested"
        when :desert
          "desert"
        when :grassland
          "waving grasslands"
        when :tundra
          "barren tundra"
        when :lake
          "a lake"
        when :pond
          "a pond"
        when :river
          "a river"
        when :bog
          "a bog"
        when :marsh
          "a marsh"
        when :swamp
          "a swamp"
        when :garden
          "a garden"
        else
          object.info.terrain.area_type.to_s
        end
      end
    end
  end

end
