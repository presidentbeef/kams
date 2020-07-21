#Contains all the movement commands
module Movement
  class << self

    #Typical moving.
    def move(event, player, room)
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
      elsif not player.balance
        player.output "You must be balanced to move."
        return
      elsif player.info.in_combat
        Combat.flee(event, player, room)
        return
      end

      new_room = $manager.find dir_exit.exit_room
      event[:exit_room] = dir_exit.exit_room

      if new_room.nil?
        player.output('You start to move in that direction, then stop when you realize that exit leads into the void.')
        return
      end

      if event[:pre]
        in_message = "#{event[:pre]}, !name comes in from the !direction."
        out_message = "#{event[:pre]}, !name leaves to the !direction."
      else
        in_message = nil
        out_message = nil
      end

      event[:to_other] = player.entrance_message(opposite_dir(event[:direction]), in_message)
      event[:to_deaf_other] = event[:to_other]
      event[:to_blind_other] = "You sense someone nearing you."
      room.remove(player)
      new_room.add(player)
      new_room.out_event(event)
      player.container = new_room.game_object_id
      event_other = event.dup
      event_other[:to_other] = player.exit_message(event_other[:direction], out_message)
      event_other[:to_blind_other] = "You hear the sounds of someone leaving."
      room.out_event(event_other)

      if player.info.followers
        player.info.followers.each do |f|
          follower = $manager.find f
          room.remove follower
          new_room.add follower

          room.output "#{follower.name.capitalize} follows #{player.name} #{event[:direction]}."
        end
      end
    end

    def flee(event, player, room)
      Combat.delete_event event
      player.balance = true
      player.info.in_combat = false
      if event.target.info.fleeing
        event.target.info.fleeing = false
        event.target.balance = true
        event.target.info.in_combat = false
        event.player = event.target
        event.target = nil
        event.to_target = event.to_player = event.to_other = nil
        event.pre = "Eyes wide with fear"
        Movement.move(event, event.player, room)
      else
        #target already fled
      end
    end

    def gait(event, player, room)
      if event[:phrase].nil?
        if player.info.entrance_message
          player.output "When you move, it looks something like:", true
          player.output player.exit_message("north")
        else
          player.output "You are walking normally."
        end
      elsif event[:phrase].downcase == "none"
        player.info.entrance_message = nil
        player.info.exit_message = nil
        player.output "You will now walk normally."
      else
        player.info.entrance_message = "#{event[:phrase]}, !name comes in from !direction."
        player.info.exit_message = "#{event[:phrase]}, !name leaves to !direction."

        player.output "When you move, it will now look something like:", true
        player.output player.exit_message("north")
      end
    end

    #Enter a portal
    def enter(event, player, room)
      portal = $manager.find(event[:object], room)
      if not player.balance
        player.output "You cannot use a portal while unbalanced."
        return
      elsif portal.nil?
        player.output "What are you trying to #{event[:portal_action]}?"
        return
      elsif not portal.is_a? Portal
        player.output "You cannot #{event[:portal_action]} #{portal.name}."
        return
      elsif portal.info.portal_action and portal.info.portal_action != event[:portal_action].to_sym
        player.output "You cannot #{event[:portal_action]} #{portal.name}."
        return
      elsif portal.info.portal_action.nil? and event[:portal_action] != "enter"
        player.output "You cannot #{event[:portal_action]} #{portal.name}."
        return
      end

      new_room = $manager.find portal.exit_room
      event[:exit_room] = portal.exit_room

      if new_room.nil?
        player.output('You start to move in that direction, then stop when you realize that way leads into the void.')
        return
      end

      event[:to_other] = portal.entrance_message(player, event[:portal_action])
      event[:to_deaf_other] = event[:to_other]
      event[:to_blind_other] = "You sense someone nearing you."
      room.remove(player)
      player.output portal.portal_message(player, event[:portal_action])
      new_room.add(player)
      new_room.out_event(event)
      player.container = new_room.game_object_id
      event_other = event.dup
      event_other[:to_other] = portal.exit_message(player, event_other[:portal_action])
      event_other[:to_blind_other] = "You hear the sounds of someone leaving."
      room.out_event(event_other)

      if player.info.followers
        player.info.followers.each do |f|
          follower = $manager.find f
          room.remove follower
          new_room.add follower

          room.output "#{follower.name.capitalize} follows #{player.name} #{event[:direction]}."
        end
      end
    end

    #Sit down.
    def sit(event, player, room)
      if not player.balance
        player.output "You cannot sit properly while unbalanced."
        return
      elsif event[:object].nil?
        if player.sitting?
          player.output('You are already sitting down.')
        elsif player.prone? and player.sit
          event[:to_player] = 'You stand up then sit on the ground.'
          event[:to_other] = "#{player.name} stands up then sits down on the ground."
          event[:to_deaf_other] = event[:to_other]
          room.output(event)
        elsif player.sit
          event[:to_player] = 'You sit down on the ground.'
          event[:to_other] = "#{player.name} sits down on the ground."
          event[:to_deaf_other] = event[:to_other]
          room.out_event(event)
        else
          player.output('You are unable to sit down.')
        end
      else
        object = $manager.find(event[:object], player.room)

        if object.nil?
          player.output('What do you want to sit on?')
        elsif not object.can? :sittable?
          player.output("You cannot sit on #{object.name}.")
        elsif object.occupied_by? player
          player.output("You are already sitting there!")
        elsif not object.has_room?
          player.output("The #{object.generic} #{object.plural? ? "are" : "is"} already occupied.")
        elsif player.sit(object)
          object.sat_on_by(player)
          event[:to_player] = "You sit down on #{object.name}."
          event[:to_other] = "#{player.name} sits down on #{object.name}."
          event[:to_deaf_other] = event[:to_other]
          room.out_event(event)
        else
          player.output('You are unable to sit down.')
        end
      end
    end

    #Stand up.
    def stand(event, player, room)
      if not player.prone?
        player.output('You are already on your feet.')
        return
      elsif not player.balance
        player.output "You cannot stand while unbalanced."
        return
      end

      if player.sitting?
        object = $manager.find(player.sitting_on, room)
      else
        object = $manager.find(player.lying_on, room)
      end

      if player.stand
        event[:to_player] = 'You rise to your feet.'
        event[:to_other] = "#{player.name} stands up."
        event[:to_deaf_other] = event[:to_other]
        room.out_event(event)
        object.evacuated_by(player) unless object.nil?
      else
        player.output('You are unable to stand up.')
      end
    end

    #Strike a pose.
    def pose(event, player, room)
      if event[:pose].downcase == "none"
        player.pose = nil
        player.output "You are no longer posing."
      else
        player.pose = event[:pose]
        player.output "Your pose is now: #{event[:pose]}."
      end
    end
  end
end
