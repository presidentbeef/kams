module Clothing
  class << self

    #Wear some clothing.
    def wear(event, player, room)

      object = player.inventory.find(event[:object])

      if object.nil?
        player.output("What #{event[:object]} are you trying to wear?")
        return
      elsif object.is_a? Weapon
        player.output "You must wield #{object.name}."
        return
      end

      if player.wear object
        event[:to_player] = "You put on #{object.name}."
        event[:to_other] = "#{player.name} puts on #{object.name}."
        room.out_event(event)
      end
    end

    #Remove some clothing.
    def remove(event, player, room)

      object = player.equipment.find(event[:object])

      if object.nil?
        player.output("What #{event[:object]} are you trying to remove?")
        return
      end

      if player.inventory.full?
        player.output("There is no room in your inventory.")
        return
      end

      if object.is_a? Weapon
        player.output("You must unwield weapons.")
        return
      end

      response = player.remove(object, event[:position])

      if response
        event[:to_player] = "You remove #{object.name}."
        event[:to_other] = "#{player.name} removes #{object.name}."
        room.out_event(event)
      else
        player.output "Could not remove #{object.name} for some reason."
      end
    end
  end
end
