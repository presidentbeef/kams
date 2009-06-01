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
	end
end
