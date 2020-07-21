#Handles custom actions for objects
module Custom
  class << self

    #Check for and handle custom events.
    def custom(event, player, room)
      object = player.search_inv(event[:target]) || room.find(event[:target])
      if object.nil?
        player.output "Not sure what you are talking about."
        return
      elsif not object.actions.include? event[:custom_action]
        player.output "You cannot do that to #{object.name}."
        return
      elsif object.can? event[:custom_action].to_sym
        object.send(event[:custom_action].to_sym, event, player, room)
      elsif object.is_a? Reacts
        event.action = event[:custom_action].to_sym
        object.alert(event)
      else
        player.output "Nothing happens."
      end
    end

  end
end
