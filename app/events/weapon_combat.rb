require 'events/combat'

module WeaponCombat

  class << self

    def slash(event, player, room)

      return if not Combat.ready? player

      weapon = get_weapon(player, :slash)
      if weapon.nil?
        player.output "You are not wielding a weapon you can slash with."
        return
      end

      target = (event.target && room.find(event.target)) || room.find(player.last_target)

      if target.nil?
        player.output "Who are you trying to attack?"
        return
      else
        return unless Combat.valid_target? player, target
      end

      player.last_target = target.goid

      event.target = target

      event[:to_other] = "#{weapon.name} flashes as #{player.name} swings it at #{target.name}."
      event[:to_target] = "#{weapon.name} flashes as #{player.name} swings it towards you."
      event[:to_player] = "#{weapon.name} flashes as you swing it towards #{target.name}."
      event[:attack_weapon] = weapon
      event[:blockable] = true

      player.balance = false
      player.info.in_combat = true
      target.info.in_combat = true

      room.out_event event

      event[:action] = :weapon_hit
      event[:combat_action] = :slash
      event[:to_other] = "#{player.name} slashes across #{target.name}'s torso with #{weapon.name}."
      event[:to_target] = "#{player.name} slashes across your torso with #{weapon.name}."
      event[:to_player] = "You slash across #{target.name}'s torso with #{weapon.name}."

      Combat.future_event event

    end

    def simple_block(event, player, room)

      return if not Combat.ready? player

      weapon = get_weapon(player, :block)
      if weapon.nil?
        player.output "You are not wielding a weapon you can block with."
        return
      end

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
        player.output "What are you trying to block?"
        return
      end

      if target.nil?
        target = events[0].player
      end

      player.last_target = target.goid

      b_event = events[0]
      if rand > 0.5
        b_event[:action] = :weapon_block
        b_event[:type] = :WeaponCombat
        b_event[:to_other] = "#{player.name} deftly blocks #{target.name}'s attack with #{weapon.name}."
        b_event[:to_player] = "#{player.name} deftly blocks your attack with #{weapon.name}."
        b_event[:to_target] = "You deftly block #{target.name}'s attack with #{weapon.name}."
      end

      event[:target] = target
      event[:to_other] = "#{player.name} raises #{player.pronoun(:possessive)} #{weapon.generic} to block #{target.name}'s attack."
      event[:to_target] = "#{player.name} raises #{player.pronoun(:possessive)} #{weapon.generic} to block your attack."
      event[:to_player] = "You raise your #{weapon.generic} to block #{target.name}'s attack."

      player.balance = false
      room.out_event event
    end

    #Wield a weapon.
    def wield(event, player, room)
      weapon = player.inventory.find(event[:weapon])
      if weapon.nil?
        weapon = player.equipment.find(event[:weapon])
        if weapon and player.equipment.get_all_wielded.include? weapon
          player.output "You are already wielding that."
        else
          player.output "What are you trying to wield?"
        end
        return
      end

      if not weapon.is_a? Weapon
        player.output "#{weapon.name} is not wieldable."
        return
      end

      if event[:side]
        side = event[:side]
        if side != "right" and side != "left"
          player.output "Which hand?"
          return
        end

        result = player.equipment.check_wield(weapon, "#{side} wield")
        if result
          player.output result
          return
        end

        result = player.equipment.wear(weapon, "#{side} wield")
        if result.nil?
          player.output "You are unable to wield that."
          return
        end
        event[:to_player] = "You grip #{weapon.name} firmly in your #{side} hand."
      else
        result = player.equipment.check_wield(weapon)

        if result
          player.output result
          return
        end

        result = player.equipment.wear(weapon)
        if result.nil?
          player.output "You are unable to wield that weapon."
          return
        end

        event[:to_player] = "You firmly grip #{weapon.name} and begin to wield it."
      end

      player.inventory.remove weapon
      event[:to_other] = "#{player.name} wields #{weapon.name}."
      room.out_event(event)
    end

    #Unwield a weapon.
    def unwield(event, player, room)

      if event[:weapon] == "right" || event[:weapon] == "left"
        weapon = player.equipment.get_wielded(event[:weapon])

        if weapon.nil?
          player.output "You are not wielding anything in your #{event[:weapon]} hand."
          return
        end
      elsif event[:weapon].nil?
        weapon = player.equipment.get_wielded
        if weapon.nil?
          player.output "You are not wielding anything."
          return
        end
      else
        weapon = player.equipment.find(event[:weapon])

        if weapon.nil?
          player.output "What are you trying to unwield?"
          return
        end

        if not [:left_wield, :right_wield, :dual_wield].include? player.equipment.position_of(weapon)
          player.output "You are not wielding #{weapon.name}."
          return
        end

      end

      if player.equipment.remove(weapon)
        player.inventory << weapon
        event[:to_player] = "You unwield #{weapon.name}."
        event[:to_other] = "#{player.name} unwields #{weapon.name}."
        room.out_event(event)
      else
        player.output "Could not unwield #{weapon.name}."
      end
    end

    def weapon_hit(event, player, room)
      Combat.delete_event event
      player.balance = true
      event.target.balance = true
      player.info.in_combat = false
      event.target.info.in_combat = false
      Combat.inflict_damage event, player, room, 10 #temporary set amount of damage for now
    end

    def weapon_block(event, player, room)
      Combat.delete_event event
      player.balance = true
      event.target.balance = true
      player.info.in_combat = false
      event.target.info.in_combat = false
      room.out_event event
    end

    private

    WeaponTypes = {
      :sword => [:charge, :thrust, :sweep, :circle_sweep, :slash, :circle_slash, :hilt_slam, :cleave, :behead, :pin, :block],
      :hammer => [:charge, :sweep, :cicle_sweep, :bash, :swing, :circle_swing, :crush, :ground_slam, :block],
      :axe => [:charge, :thrust, :feint_thrust, :throw, :sweep, :circle_sweep, :bash, :slash, :cleave, :behead, :block],
      :dagger => [:charge, :thrust, :feint_thrust, :stab, :gouge, :throw, :slash, :circle_slash, :backstab, :pin, :block],
      :pole => [:charge, :thrust, :feint_thrust, :lunge, :throw, :sweep, :circle_sweep, :pin, :block]
    }

    def weapon_can? type, attack
      WeaponTypes[type.to_sym].include? attack.to_sym
    end

    def get_weapon player, attack
      weapon = nil
      player.equipment.get_all_wielded.each do |w|
        if w.is_a? Weapon and w.info.weapon_type and weapon_can?(w.info.weapon_type, attack)
          weapon = w
          break
        end
      end

      weapon
    end
  end
end
