module Mobiles
  class << self
    def teach(event, player, room)
      object = $manager.find(event.object, room)

      if object.nil?
        player.output "Who are you trying to teach?"
        return
      end
    end

    def expire(event, player, room)
      $manager.delete_object player
    end

    def respawn(event, player, room)
      player.alive = true
      player.info.stats.health = player.info.stats.max_health
      event.room.add player
    end

    def teleport(event, player, room)
      if event[:object].is_a? GameObject
        object = event[:object]
      else
        object = $manager.find event[:object]
      end

      object.output event[:to_object] if event[:to_object]

      Admin.aput(event, player, room)

      if event[:to_room]
        room = $manager.find self.container
        room.output event[:to_room], object
      end

      if event[:to_exit_room]
        exit_room = $manager.find object.container
        exit_room.output event[:to_exit_room], object
      end
    end
  end
end
