require 'events/combat'

module MartialCombat
  class << self

    def kick(event, player, room)
      return if not Combat.ready? player

      target = (event.target && room.find(event.target)) || room.find(player.last_target)

      if target.nil?
        player.output "Who are you trying to attack?"
        return
      else
        return unless Combat.valid_target? player, target
      end

      player.last_target = target.goid

      event.target = target

      event[:to_other] = "#{player.name} kicks #{player.pronoun(:possessive)} foot out at #{target.name}."
      event[:to_target] = "#{player.name} kicks #{player.pronoun(:possessive)} foot at you."
      event[:to_player] = "You balance carefully and kick your foot out towards #{target.name}."
      event[:blockable] = true

      player.balance = false
      player.info.in_combat = true
      target.info.in_combat = true

      room.out_event event

      event[:action] = :martial_hit
      event[:combat_action] = :kick
      event[:to_other] = "#{player.name} kicks #{target.name} with considerable violence."
      event[:to_target] = "#{player.name} kicks you rather violently."
      event[:to_player] = "Your kick makes good contact with #{target.name}."

      Combat.future_event event
    end

    def punch(event, player, room)
      return unless Combat.ready? player

      target = (event.target && room.find(event.target)) || room.find(player.last_target)

      if target.nil?
        player.output "Who are you trying to attack?"
        return
      else
        return unless Combat.valid_target? player, target
      end

      player.last_target = target.goid

      event.target = target

      event[:to_other] = "#{player.name} swings #{player.pronoun(:possessive)} clenched fist at #{target.name}."
      event[:to_target] = "#{player.name} swings #{player.pronoun(:possessive)} fist straight towards your face."
      event[:to_player] = "You clench your hand into a fist and swing it at #{target.name}."
      event[:blockable] = true

      player.balance = false
      player.info.in_combat = true
      target.info.in_combat = true

      room.out_event event

      event[:action] = :martial_hit
      event[:combat_action] = :punch
      event[:to_other] = "#{player.name} punches #{target.name} directly in the face."
      event[:to_target] = "You stagger slightly as #{player.name} punches you in the face."
      event[:to_player] = "Your fist lands squarely in #{target.name}'s face."

      Combat.future_event event
    end

    def simple_dodge(event, player, room)
      return unless Combat.ready? player

      target = (event.target && room.find(event.target)) || room.find(player.last_target)

      if target == player
        player.output "You cannot block yourself."
        return
      elsif target
        events = Combat.find_events(:player => target, :target => player, :blockable => true)
      else
        events = Combat.find_events(:target => player, :blockable => true)
      end

      if events.empty?
        player.output "What are you trying to dodge?"
        return
      end

      if target.nil?
        target = events[0].player
      end

      player.last_target = target.goid

      b_event = events[0]
      if rand > 0.5
        b_event[:action] = :martial_miss
        b_event[:type] = :MartialCombat
        b_event[:to_other] = "#{player.name} twists away from #{target.name}'s attack."
        b_event[:to_player] = "#{player.name} twists away from your attack."
        b_event[:to_target] = "You manage to twist your body away from #{target.name}'s attack."
      end

      event[:target] = target
      event[:to_other] = "#{player.name} attempts to dodge #{target.name}'s attack."
      event[:to_target] = "#{player.name} attempts to dodge your attack."
      event[:to_player] = "You attempt to dodge #{target.name}'s attack."

      player.balance = false
      room.out_event event
    end

    def martial_hit(event, player, room)
      Combat.delete_event event
      player.balance = true
      event.target.balance = true
      player.info.in_combat = false
      event.target.info.in_combat = false
      Combat.inflict_damage event, player, room, 8 #temporary set amount of damage for now
    end

    def martial_miss(event, player, room)
      Combat.delete_event event
      player.balance = true
      event.target.balance = true
      player.info.in_combat = false
      event.target.info.in_combat = false
      room.out_event event
    end

  end
end
