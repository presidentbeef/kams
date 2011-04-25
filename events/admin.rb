#This module contains all the commands for administering the game.
#
#Note: need to add documentation of syntax, that would help
module Admin
  class << self

    #Moves an object into a specified container.
    #
    # APUT [OBJECT] IN [CONTAINER]
    def aput(event, player, room)
      if event[:object].is_a? GameObject
        object = event[:object]
      else
        event[:object] = player.container if event[:object].downcase == "here"
        object = find_object(event[:object], event)
      end

      container = find_object(event[:in], event)

      if object.nil?
        player.output "Cannot find #{event[:object]} to move."
        return
      elsif event[:in] == "!world"
        container = $manager.find object.container
        container.inventory.remove(object) unless container.nil?
        object.container = nil
        player.output "Removed #{object} from any containers."
        return
      elsif event[:in].downcase == "here"
        container = $manager.find player.container
        if container.nil?
          player.output "Cannot find #{event[:in]} "
          return
        end
      elsif container.nil?
        player.output "Cannot find #{event[:in]} "
        return
      end

      if not object.container.nil?
        current_container = $manager.find object.container
        current_container.inventory.remove(object) if current_container
      end

      if container.is_a? Container
        container.add object
      else
        container.inventory.add(object)
        object.container = container.goid
      end

      player.output "Moved #{object} into #{container}"
    end

    #Loads/Reloads a .rb file. Do not provide the extension.
    #
    # ARELOAD [FILENAME]
    def areload(event, player, room)
      begin
        result = load "#{event[:object]}.rb"
        player.output "Reloaded #{event[:object]}: #{result}"
      rescue LoadError
        player.output "Unable to load #{event[:object]}"
      end
    end

    #Creates a new object.
    #
    # ACREATE <OBJECT_TYPE> <NAME>
    def acreate(event, player, room)
      class_name = event[:object]

      class_name[0,1] = class_name[0,1].capitalize

      if Object.const_defined? class_name
        klass = Object.const_get(class_name)
      else
        player.output "No such thing. Sorry."
        return
      end

      if not klass <= GameObject  or klass == Player
        player.output "You cannot create a #{klass.class}."
        return
      end

      vars = {}
      vars[:@name] = event[:name] if event[:name]
      vars[:@alt_names] = event[:alt_names] if event[:alt_names]
      vars[:@generic] = event[:generic] if event[:generic]
      args = event[:args]

      object = $manager.create_object(klass, room, args, vars)

      if room
        event[:to_player] = "Frowning in concentration, you make vague motions with your hands. There is a small flash of light as #{object.name} appears."
        event[:to_other] = "Frowning in concentration, #{player.name} makes vague motions with #{player.pronoun(:possessive)} hands. There is a small flash of light as #{object.name} appears."
        room.out_event event
      end

      player.output "Created: #{object}"
      object
    end

    def acdoor event, player, room

      exit_room = nil
      if event[:exit_room].nil?
        out = find_object event[:direction], event
        if out and out.is_a? Exit
          exit_room = $manager.find out.exit_room
          other_side = $manager.find opposite_dir(event[:direction]), out.exit_room

          if other_side
            $manager.delete_object other_side
            player.output "Removed opposite exit (#{other_side})."
          else
            player.output "Could not find opposite exit"
          end

          $manager.delete_object out
          player.output "Removed exit (#{out})."
        end
      else
        exit_room = $manager.get_object event[:exit_room]
      end

      if exit_room.nil?
        player.output "Cannot find #{event[:exit_room]} to connect to."
        return
      end

      door_here = $manager.create_object Door, room, exit_room.goid, :@alt_names => [event[:direction]], :@name => "a door to the #{event[:direction]}"
      door_there = $manager.create_object Door, exit_room, room.goid, :@alt_names => [opposite_dir(event[:direction])], :@name => "a door to the #{opposite_dir event[:direction]}"
      door_here.connect_to door_there

      player.output "Created: #{door_here}"
      player.output "Created: #{door_there}"

      if room
        event[:to_player] = "Frowning in concentration, you make vague motions with your hands. There is a small flash of light as #{door_here.name} to #{exit_room.name} appears."
        event[:to_other] = "Frowning in concentration, #{player.name} makes vague motions with #{player.pronoun(:possessive)} hands. There is a small flash of light as #{door_here.name} to #{exit_room.name} appears."
        room.out_event event
      end
    end

    #Creates a portal.
    def acportal(event, player, room)
      object = Admin.acreate(event, player, room)
      if event[:portal_action] and event[:portal_action].downcase != "enter"
        object.info.portal_action = event[:portal_action].downcase.to_sym
      end
    end

    #Command for editing portals.
    def portal(event, player, room)
      object = find_object(event[:object], event)
      if object.nil?
        player.output "Cannot find #{event[:object]}"
        return
      elsif not object.is_a? Portal
        player.output "That is not a portal."
        return
      end

      value = event[:value]

      case event[:setting]
      when "action"
        value.downcase!
        if value == "enter"
          object.info.delete :portal_action
          player.output "Set portal action to enter"
        elsif ["jump", "climb", "crawl"].include? value
          object.info.portal_action = value.downcase.to_sym
          player.output "Set portal action to #{value}"
        else
          player.output "#{value} is not a valid portal action."
        end
      when "exit"
        if value.downcase == "!nothing" or value.downcase == "nil"
          object.info.delete :exit_message
        else
          if value[-1,1] !~ /[!.?"']/
            value << "."
          end
          object.info.exit_message = value
        end
        player.output "#{object.name} exit message set to: #{object.info.exit_message}"
      when "entrance"
        if value.downcase == "!nothing" or value.downcase == "nil"
          object.info.delete :entrance_message
        else
          if value[-1,1] !~ /[!.?"']/
            value << "."
          end
          object.info.entrance_message = value
        end
        player.output "#{object.name} entrance message set to: #{object.info.entrance_message}"
      when "portal"
        if value.downcase == "!nothing" or value.downcase == "nil"
          object.info.delete :portal_message
        else
          if value[-1,1] !~ /[!.?"']/
            value << "."
          end
          object.info.portal_message = value
        end
        player.output "#{object.name} portal message set to: #{object.info.portal_message}"
      else
        player.output "Valid options: action, exit, entrance, or portal."
      end
    end

    #Create a new area.
    def acarea(event, player, room)
      area = $manager.create_object(Area, nil, nil, {:@name => event[:name]})
      player.output "Created: #{area}"
    end

    #Create room, with an exit to the new room and back to the current room.
    def acroom(event, player, room)
      area = nil
      if room.container
        area = $manager.get_object(room.container)
      end

      new_room = $manager.create_object(Room, area, nil, :@name => event[:name])
      out_exit = $manager.create_object(Exit, room, new_room.goid, :@alt_names => [event[:out_dir]])
      in_exit = $manager.create_object(Exit, new_room, room.goid, :@alt_names => [event[:in_dir]])

      player.output "Created: #{new_room}"
      player.output "Created: #{out_exit}"
      player.output "Created: #{in_exit}"

      if room
        room.output "There is a small flash of light as a new room appears to the #{event[:out_dir]}."
      end

    end

    #Sets a server configuration option.
    def aconfig(event, player, room)

      if event[:setting].nil?
        player.output "Current configuration:\n#{ServerConfig}"
        return
      end

      setting = event[:setting].downcase.to_sym

      if setting == :reload
        ServerConfig.reload
        player.output "Reloaded configuration:\n#{ServerConfig}"
        return
      elsif not ServerConfig.has_setting? setting
        player.output "No such setting."
        return
      end

      value = event[:value]
      if value =~ /^\d+$/
        value = value.to_i
      end

      ServerConfig[setting] = value

      player.output "New configuration:\n#{ServerConfig}"
    end

    #Deletes an object.
    def adelete(event, player, room)
      if event[:object] and event[:object].split.first.downcase == "all"
        log event[:object].split
        klass = event[:object].split[1]
        klass.capitalize! unless klass[0,1] == klass[0,1].upcase
        begin
          klass = Module.const_get klass.to_sym
        rescue NameError
          player.output "No such object type."
          return
        end

        objects = $manager.find_all("class", klass)

        objects.each do |obj|
          e = event.dup
          e[:object] = obj.goid

          Admin.adelete(e, player, room)
        end

        return
      end

      object = find_object(event[:object], event)

      if object.nil?
        player.output "Cannot find #{event[:object]} to delete."
        return
      elsif object.is_a? Player
        player.output "Use DELETEPLAYER to delete players."
        return
      end

      object_container = object.container

      $manager.delete_object(object)

      if room and room.goid == object.container
        event[:to_player] = "You casually wave your hand and #{object.name} disappears."
        event[:to_other] = "With a casual wave of #{player.pronoun(:possessive)} hand, #{player.name} makes #{object.name} disappear."
        room.out_event event
      else
        player.output "You casually wave your hand and #{object.name} disappears."
      end

      player.output "#{object} deleted."
    end

    #Describe an object.
    def adesc(event, player, room)
      object = nil
      if event[:object].downcase == "here"
        object = room
      else
        object = find_object(event[:object], event)
      end

      if object.nil?
        player.output "Cannot find #{event[:object]}."
        return
      end

      if event[:inroom]
        if event[:desc].nil? or event[:desc].downcase == "false"
          object.show_in_look = false
          player.output "#{object.name} will not be shown in the room description."
        else
          object.show_in_look= event[:desc]
          player.output "The room will show #{object.show_in_look}"
        end
      else
        object.instance_variable_set(:@short_desc, event[:desc])
        player.output "#{object.name} now looks like:\n#{object.short_desc}"
      end
    end

    #ASHOW and AHIDE. Either hides an object by setting its show_in_look to "" or shows it by setting
    #show_in_look to false.
    def ahide(event, player, room)
      object = find_object(event[:object], event)

      if object.nil?
        player.output "Cannot find #{event[:object]}."
        return
      end

      if event[:hide]
        object.show_in_look = ""
        player.output "#{object.name} is now hidden."
      elsif object.show_in_look == ""
        object.show_in_look = false
        player.output "#{object.name} is no longer hidden."
      else
        player.output "This object is not hidden."
      end
    end

    #Looks at an object.
    def alook(event, player, room)
      if event[:at].nil?
        object = room
      elsif event[:at].downcase == "here"
        object = $manager.find player.container
      else
        object = find_object(event[:at], event)
      end

      if object.nil?
        player.output "Cannot find #{event[:at]} to inspect."
        return
      end

      output = "Object: #{object}\n"
      output << "Attributes:\n"

      object.instance_variables.sort.each do |var|
        val = object.instance_variable_get(var)
        if var == :@observer_peers
          val = val.keys.map {|k| k.to_s }
        end
        output << "\t#{var} = #{val}\n"
      end

      output << "\r\nInventory:\r\n"

      if object.respond_to? :inventory
        object.inventory.each do |o|
          output << "\t#{o.name} # #{o.goid}\n"
        end
      else
        output << "\tNo Inventory"
      end

      if object.respond_to? :equipment
        output << "\r\nEquipment:\r\n"
        object.equipment.inventory.each do |o|
          output << "\t#{o.name} # #{o.goid}\n"
        end
        output << "\t#{object.equipment.equipment.inspect}\n"
      end

      player.output(output)
    end

    #Lists objects in the world
    def alist(event, player, room)
      objects = nil
      if event[:match].nil?
        objects = $manager.find_all("class", :GameObject)
      else
        objects = $manager.find_all(event[:match], event[:attrib])
      end

      if objects.empty?
        player.output "Nothing like that to list!"
      else
        output = []
        objects.each do |o|
          output << "\t" + o.to_s
        end

        output = output.join("\n")

        player.output(output)
      end
    end

    #Shows an object's containers.
    def whereis(event, player, room)
      object = find_object(event[:object], event)

      if object.nil?
        player.output "Could not find #{event[:object]}."
        return
      end

      if object.container.nil?
        if object.can? :area and not object.area.nil? and object.area != object
          area = $manager.get_object object.area || "nothing"
          player.output "#{object} is in #{area}."
        else
          player.output "#{object} is not in anything."
        end
      else
        container = $manager.get_object object.container
        if container.nil?
          player.output "Container for #{object} not found."
        else
          player.output "#{object} is in #{container}."
          event[:object] = container.goid
          whereis(event, player, room)
        end
      end
    end

    #Sets object variables.
    def aset(event, player, room)
      if event[:object].downcase == "here"
        event[:object] = player.container
      elsif event[:object] and event[:object].split.first.downcase == "all"
        log event[:object].split
        klass = event[:object].split[1]
        klass.capitalize! unless klass[0,1] == klass[0,1].upcase
        begin
          klass = Module.const_get klass.to_sym
        rescue NameError
          player.output "No such object type."
          return
        end

        objects = $manager.find_all("class", klass)

        objects.each do |obj|
          e = event.dup
          e[:object] = obj.goid

          Admin.aset(e, player, room)
        end

        return
      end

      object = find_object(event[:object], event)

      if object.nil?
        player.output "Cannot find #{event[:object]} to edit."
        return
      end

      attrib = event[:attribute]

      if attrib[0,1] != "@"
        value = event[:value]
        if value.downcase == "!nothing" or value.downcase == "nil"
          value = nil
        end

        if value and value[-1,1] !~ /[!.?"']/
          value << "."
        end

        case attrib.downcase
        when "smell"
          if value.nil?
            object.info.delete :smell
            player.output "#{object.name} will no longer smell."
          else
            object.info.smell = value
            player.output "#{object.name} will now smell like: #{object.info.smell}"
          end
          return
        when "feel", "texture"
          if value.nil?
            object.info.delete :texture
            player.output "#{object.name} will no longer have a particular texture."
          else
            object.info.texture = value
            player.output "#{object.name} will now feel like: #{object.info.texture}"
          end
          return
        when "taste"
          if value.nil?
            object.info.delete :taste
            player.output "#{object.name} will no longer have a particular taste."
          else
            object.info.taste = value
            player.output "#{object.name} will now taste like: #{object.info.taste}"
          end
          return
        when "sound", "listen"
          if value.nil?
            object.info.delete :sound
            player.output "#{object.name} will no longer make sounds."
          else
            object.info.sound = value
            player.output "#{object.name} will now sound like: #{object.info.sound}"
          end
          return
        else
          player.output "What are you trying to set?"
          return
        end
      end

      if not object.instance_variables.include? attrib and not object.instance_variables.include? attrib.to_sym and not event[:force]
        player.output "#{object}:No such setting/variable/attribute: #{attrib}"
        return
      else
        current_value = object.instance_variable_get(attrib)
        if current_value.is_a? Array
          object.instance_variable_set(attrib, event[:value].split(/s*"(.*?)"\s*|\s+/))
          player.output "Set #{object} attribute #{attrib} to #{event[:value].inspect}"
        else
          value = event[:value] #for ease
          if value.split.length == 1
            case value.downcase
            when "true"
              value = true
            when "false"
              value = false
            when /^:/
              value = value[1..-1].to_sym
            when "nil"
              value = nil
            when /^[0-9]+$/
              value = value.to_i unless current_value.is_a? String
            when "!nothing"
              value = ""
            when "!delete"
              object.instance_eval { remove_instance_variable(attrib) }
              player.output "Removed attribute #{attrib} from #{object}"
              return
            end
          end

          object.instance_variable_set(attrib, value)
          player.output "Set #{object} attribute #{attrib} to #{value}"
        end
      end
    end

    #Display and edit the Info object for a GameObject.
    def ainfo(event, player, room)
      if event[:object].downcase == "here"
        event[:object] = player.container
      elsif event[:object].downcase == "me"
        event[:object] = player
      elsif event[:object] and event[:object].split.first.downcase == "all"
        log event[:object].split
        klass = event[:object].split[1]
        klass.capitalize! unless klass[0,1] == klass[0,1].upcase
        begin
          klass = Module.const_get klass.to_sym
        rescue NameError
          player.output "No such object type."
          return
        end

        objects = $manager.find_all("class", klass)

        objects.each do |obj|
          e = event.dup
          e[:object] = obj.goid

          Admin.ainfo(e, player, room)
        end

        return
      end

      object = find_object(event[:object], event)

      if object.nil?
        player.output "What object? #{event[:object]}"
        return
      end

      case event[:command]
      when "set"
        value = event[:value] #for ease
        if value.split.length == 1
          if value == "true"
            value = true
          elsif value == "false"
            value = false
          elsif value[0,1] == ":"
            value = value[1..-1].to_sym
          elsif value == "nil"
            value = nil
          elsif value.match(/^[0-9]+$/)
            value = value.to_i
          elsif value.downcase == "!nothing"
            value = ""
          end
        end
        object.info.set(event[:attrib], value)
        player.output "Set #{event[:attrib]} to #{object.info.get(event[:attrib])}"
      when "delete"
        object.info.delete(event[:attrib])
        player.output "Deleted #{event[:attrib]} from #{object}"
      when "show"
        player.output object.info.inspect
      when "clear"
        object.info = Info.new
        player.output "Completely cleared info for #{object}."
      else
        player.output "Huh? What?"
      end
    end

    #Lists all players currently online
    def awho(event, player, room)
      players = $manager.find_all('class', Player)

      names = []
      players.each do |playa|
        names << playa.name
      end

      player.output('Players currently online:', true)
      player.output(names.join(', '))
    end

    #Lists players online and how many of what objects are in memory
    def astatus(event, player, room)
      awho(event, player, room)
      total_objects = $manager.game_objects_count
      player.output("Object Counts:" , true)
      $manager.type_count.each do |obj, count|
        player.output("#{obj}: #{count}", true)
      end
      player.output("Total Objects: #{total_objects}")
    end

    #Change log settings, view logs.
    def alog(event, player, room)
      if event[:command].nil?
        player.output "What do you want to do with the log?"
        return
      else
        command = event[:command].downcase
      end

      case command
      when /^players?$/
        if event[:value]
          lines = event[:value].to_i
        else
          lines = 10
        end

        player.output tail('logs/player.log', lines)
      when 'server'
        if event[:value]
          lines = event[:value].to_i
        else
          lines = 10
        end

        player.output tail('logs/server.log', lines)
      when 'system'
        if event[:value]
          lines = event[:value].to_i
        else
          lines = 10
        end

        $LOG.dump

        player.output tail('logs/system.log', lines)
      when 'flush'
        log('Flushing log')
        $LOG.dump
        player.output 'Flushed log to disk.'
      when 'ultimate'
        ServerConfig[:log_level] = 3
        player.output "Log level now set to ULTIMATE."
      when 'high'
        ServerConfig[:log_level] = 2
        player.output "Log level now set to high."
      when 'low', 'normal'
        ServerConfig[:log_level] = 1
        player.output "Log level now set to normal."
      when 'off'
        ServerConfig[:log_level] = 0
        player.output "Logging mostly turned off. You may also want to turn off debugging."
      when 'debug'
        ServerConfig[:debug] = !$DEBUG
        player.output "Debug info is now: #{$DEBUG ? 'on' : 'off'}"
      else
        player.output 'Possible settings: Off, Debug, Normal, High, or Ultimate'
      end
    end

    #Copies an object (but with new goid)
=begin
    def acopy(event, player, room)
      object = find_object(event[:object], event)
      if object.nil?
        player.output "Cannot find #{event[:object]} to copy."
      end

      new_object = object.dup
      new_object.instance_variable_set(:@game_object_id, Guid.new.to_s)
      $manager.add_object(new_object)
      room.add(new_object)
      player.output "Created #{new_object}"
    end
=end

    #Teach yourself a skill.
    #
    #Does nothing righ now.
    def alearn(event, player, room)
    end

    #Teach someone else a skill.
    #
    #Does nothing right now.
    def ateach(event, player, room)
      object = find_object(event[:target], event)
      if object.nil?
        player.output "Teach who what where?"
        return
      end

      alearn(event, object, room)
    end

    #SAVE POINT
    def asave(event, player, room)
      log "#{player.name} initiated manual save."
      $manager.save_all
      player.output "Save complete. Check log for details."
    end

    #Force something or someone to perform an action.
    def aforce(event, player, room)
      object = find_object(event[:target], event)
      if object.nil?
        player.output "Force who?"
        return
      elsif object.is_a? Mobile
        unless object.info.redirect_output_to == player.goid
          object.info.redirect_output_to = player.goid

          after 10 do
            object.info.redirect_output_to = nil
          end
        end
      end

      player.add_event(CommandParser.parse(object, event[:command]))
    end

    #View what a GameObject sees.
    def awatch(event, player, room)
      object = find_object(event[:target], event)
      if object.nil?
        player.output "What mobile do you want to watch?"
        return
      elsif not object.is_a? Mobile
        player.output "You can only use this to watch mobiles."
        return
      end

      case event[:command]
      when "start"
        if object.info.redirect_output_to == player.goid
          player.output "You are already watching #{object.name}."
        else
          object.info.redirect_output_to = player.goid
          player.output "Watching #{object.name}."
          object.output "#{player.name} is watching you."
        end
      when "stop"
        if object.info.redirect_output_to != player.goid
          player.output "You are not watching #{object.name}."
        else
          object.info.redirect_output_to = nil
          player.output "No longer watching #{object.name}."
        end
      else
        if object.info.redirect_output_to != player.goid
          object.info.redirect_output_to = player.goid
          player.output "Watching #{object.name}."
          object.output "#{player.name} is watching you."
        else
          object.info.redirect_output_to = nil
          player.output "No longer watching #{object.name}."
        end
      end
    end

    #Set a comment on an object.
    def acomment(event, player, room)
      object = find_object(event[:target], event)
      if object.nil?
        player.output "Cannot find:#{event[:target]}"
        return
      end

      object.comment = event[:comment]
      player.output "Added comment: '#{event[:comment]}'\nto#{object}"
    end

    #Manage reactions for an object.
    def areaction(event, player, room)

      if event[:command] == "reload" and event[:object] and event[:object].downcase == "all"
        objects = $manager.find_all("class", Reacts)

        objects.each do |o|
          o.reload_reactions
        end

        player.output "Updated reactions for #{objects.length} objects."
      elsif event[:object] and event[:object].split.first.downcase == "all"
        klass = event[:object].split[1]
        klass.capitalize! unless klass[0,1] == klass[0,1].upcase
        begin
          klass = Module.const_get klass.to_sym
        rescue NameError
          player.output "No such object type."
          return
        end

        objects = $manager.find_all("class", klass)

        objects.each do |obj|
          e = event.dup
          e[:object] = obj.goid

          player.output "(Doing #{obj})"
          Admin.areaction(e, player, room)
        end
      else
        if event[:object] == "here"
          object = room
        else
          object = find_object(event[:object], event)
        end

        if object.nil?
          player.output "Cannot find:#{event[:object]}"
          return
        elsif not object.is_a? Reacts and (event[:command] == "load" or event[:command] == "reload")
          player.output "Object cannot react, adding react ability."
          object.extend(Reacts)
        end

        case event[:command]
        when "add"
          if object.actions.add? event[:action_name]
            player.output "Added #{event[:action_name]}"
          else
            player.output "Already had a reaction by that name."
          end
        when "delete"
          if object.actions.delete? event[:action_name]
            player.output "Removed #{event[:action_name]}"
          else
            player.output "That verb was not associated with this object."
          end
        when "load"
          unless File.exist? "objects/reactions/#{event[:file]}.rx"
            player.output "No such reaction file - #{event[:file]}"
            return
          end

          object.load_reactions event[:file]
          player.output "Probably loaded reactions."
        when "reload"
          object.reload_reactions if object.can? :reload_reactions
          player.output "Probably reloaded reactions."
        when "clear"
          object.unload_reactions if object.can? :unload_reactions
          player.output "Probably cleared out reactions."
        when "show"
          if object.actions and not object.actions.empty?
            player.output "Custom actions: #{object.actions.to_a.sort.join(' ')}", true
          end

          if object.can? :show_reactions
            player.output object.show_reactions
          else
            player.output "Object does not react."
          end
        else
          player.output("Options:", true)
          player.output("areaction load <object> <file>", true)
          player.output("areaction reload <object> <file>", true)
          player.output("areaction [add|delete] <object> <action>", true)
          player.output("areaction [clear|show] <object>")
        end
      end
    end

    #Lists existing areas
    def areas(event, player, room)
      areas = $manager.find_all('class', Area)

      if areas.empty?
        player.output "There are no areas."
        return
      end

      player.output areas.map {|a| "#{a.name} -  #{a.inventory.find_all('class', Room).length} rooms (#{a.info.terrain.area_type})" }
    end

    #Settings for the area or room terrain
    def terrain(event, player, room)
      if event[:target] == "area"
        if room.area.nil?
          player.output "This room is not in an area."
          return
        end

        room.area.info.terrain.area_type = event[:value].downcase.to_sym

        player.output "Set #{room.area.name} terrain type to #{room.area.info.terrain.area_type}"

        return
      end

      case event[:setting].downcase
      when "type"
        room.info.terrain.room_type = event[:value].downcase.to_sym
        player.output "Set #{room.name} terrain type to #{room.info.terrain.room_type}"
      when "indoors"
        if event[:value] =~ /yes|true/i
          room.info.terrain.indoors = true
          player.output "Room is now indoors."
        elsif event[:value] =~ /no|false/i
          room.info.terrain.indoors = false
          player.output "Room is now outdoors."
        else
          player.output "Indoors: yes or no?"
        end
      when "water"
        if event[:value] =~ /yes|true/i
          room.info.terrain.water = true
          player.output "Room is now water."
        elsif event[:value] =~ /no|false/i
          room.info.terrain.water = false
          player.output "Room is now dry."
        else
          player.output "Water: yes or no?"
        end
      when "underwater"
        if event[:value] =~ /yes|true/i
          room.info.terrain.underwater = true
          player.output "Room is now underwater."
        elsif event[:value] =~ /no|false/i
          room.info.terrain.underwater = false
          player.output "Room is now above water."
        else
          player.output "Underwater: yes or no?"
        end
      else
        player.output "What are you trying to set?"
      end
    end

    #Restarts the server.
    def restart(event, player, room)
      $manager.restart
    end

    #Show admin help files.
    def ahelp(event, player, room)
      Generic.help(event, player, room)
    end

    #Delete a player/character.
    def delete_player(event, player, room)
      name = event.object
      if not $manager.player_exist? name
        player.output "No such player found: #{name}"
        return
      elsif $manager.find name
        player.output "Player is currently logged in. Deletion aborted."
        return
      elsif name == player.name.downcase
        player.output "You cannot delete yourself this way. Use DELETE ME PLEASE instead."
        return
      end

      $manager.delete_player name

      if $manager.find name or $manager.player_exist? name
        player.output "Something went wrong. Player still exists."
      else
        player.output "#{name} deleted."
      end
    end

    private

    #Tail a file
    def tail file, lines = 10
      require 'util/tail'

      output = []
      File::Tail::Logfile.tail(file, :backward => lines, :return_if_eof => true) do |line|
        output << line.strip
      end

      output << "(#{output.length} lines shown.)"
    end

    #Looks in player's inventory and room for name.
    #Then checks at global level for GOID.
    def find_object(name, event)
      $manager.find(name, event[:player]) || $manager.find(name, event[:player].container) || $manager.get_object(name)
    end
  end
end
