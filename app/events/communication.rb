#Communication commands.
module Communication
  class << self
    #Says something to the room or to a specific player.
    def say(event, player, room)
      phrase = event[:phrase]
      target = event[:target] && room.find(event[:target])
      prefix = event[:pre]

      if prefix
        prefix << ", "
      else
        prefix = ""
      end

      if phrase.nil?
        player.output("Huh?")
        return
      elsif event[:target] and target.nil?
        player.output("Say what to whom?")
        return
      elsif target and target == player
        player.output "Talking to yourself again?"
        return
      elsif target
        to_clause = " to #{target.name}"
        ask_clause = " #{target.name}"
      else
        to_clause = ""
        ask_clause = ""
      end

      phrase[0,1] = phrase[0,1].capitalize
      phrase.gsub!(/(\s|^|\W)(i)(\s|$|\W)/) { |match| match.sub('i', 'I') }

      case phrase
      when /:\)$/
        rvoice = "smiles and "
        pvoice = "smile and "
      when /:\($/
        rvoice = "frowns and "
        pvoice = "frown and "
      when /:D$/
        rvoice = "laughs as #{player.pronoun} "
        pvoice = "laugh as you "
      else
        rvoice = ""
        pvoice = ""
      end

      phrase = phrase.gsub(/\s*(:\)|:\()|:D/, '').strip.gsub(/\s{2,}/, ' ')

      case phrase[-1..-1]
      when "!"
        pvoice += "exclaim"
        rvoice += "exclaims"
      when "?"
        pvoice += "ask"
        rvoice += "asks"
      when "."
        pvoice += "say"
        rvoice += "says"
      else
        pvoice += "say"
        rvoice += "says"
        ender = "."
      end

      phrase = "<say>\"#{phrase}#{ender}\"</say>"

      event[:target] = target
      if target and pvoice == "ask"
        event[:to_target] = prefix + "#{player.name} #{rvoice} you, #{phrase}"
        event[:to_player] = prefix + "you #{pvoice} #{target.name}, #{phrase}"
        event[:to_other] = prefix + "#{player.name} #{rvoice} #{target.name}, #{phrase}"
        event[:to_blind_target] = "Someone asks, #{phrase}"
        event[:to_blind_other] = "Someone asks, #{phrase}"
        event[:to_deaf_target] = "#{player.name} seems to be asking you something."
        event[:to_deaf_other] = "#{player.name} seems to be asking #{target.name} something."
      elsif target
        event[:to_target] = prefix + "#{player.name} #{rvoice} to you, #{phrase}"
        event[:to_player] = prefix + "you #{pvoice} to #{target.name}, #{phrase}"
        event[:to_other] = prefix + "#{player.name} #{rvoice} to #{target.name}, #{phrase}"
        event[:to_blind_target] = "Someone #{rvoice}, #{phrase}"
        event[:to_blind_other] = "Someone #{rvoice}, #{phrase}"
        event[:to_deaf_target] = "You see #{player.name} say something to you."
        event[:to_deaf_other] = "You see #{player.name} say something to #{target.name}."
      else
        event[:to_player] = prefix + "you #{pvoice}, #{phrase}"
        event[:to_other] = prefix + "#{player.name} #{rvoice}, #{phrase}"
        event[:to_blind_other] = "Someone #{rvoice}, #{phrase}"
        event[:to_deaf_target] = "You see #{player.name} say something."
        event[:to_deaf_other] = "You see #{player.name} say something."
      end

      room.out_event(event)
    end

    #Whispers to another thing.
    def whisper(event, player, room)
      object = room.find(event[:to], Player)

      if object.nil?
        player.output("To whom are you trying to whisper?")
        return
      elsif object == player
        player.output("Whispering to yourself again?")
        event[:to_other] = "#{player.name} whispers to #{player.pronoun(:reflexive)}."
        room.out_event(event, player)
        return
      end

      phrase = event[:phrase]

      if phrase.nil?
        player.ouput "What are you trying to whisper?"
        return
      end

      prefix = event[:pre]

      if prefix
        prefix << ", "
      else
        prefix = ""
      end

      phrase[0,1] = phrase[0,1].capitalize

      last_char = phrase[-1..-1]

      unless ["!", "?", "."].include? last_char
        ender = "."
      end

      phrase = ", <say>\"#{phrase}#{ender}\"</say>"

      event[:target] = object
      event[:to_player] = prefix + "you whisper to #{object.name}#{phrase}"
      event[:to_target] = prefix + "#{player.name} whispers to you#{phrase}"
      event[:to_other] = prefix + "#{player.name} whispers quietly into #{object.name}'s ear."
      event[:to_other_blind] = "#{player.name} whispers."
      event[:to_target_blind] = "Someone whispers to you#{phrase}"

      room.out_event(event)
    end

    #Tells someone something.
    def tell(event, player, room)
      target = $manager.find event[:target]
      unless target and target.is_a? Player
        player.output "That person is not available."
        return
      end

      if target == player
        player.output "Talking to yourself?"
        return
      end

      phrase = event[:message]

      last_char = phrase[-1..-1]

      unless ["!", "?", "."].include? last_char
        phrase << "."
      end

      phrase[0,1] = phrase[0,1].upcase
      phrase = phrase.strip.gsub(/\s{2,}/, ' ')

      player.output "You tell #{target.name}, <tell>\"#{phrase}\"</tell>"
      target.output "#{player.name} tells you, <tell>\"#{phrase}\"</tell>"
      target.reply_to = player.name
    end

    #Reply to a tell.
    def reply(event, player, room)
      unless player.reply_to
        player.output "There is no one to reply to."
        return
      end

      event[:target] = player.reply_to

      tell(event, player, room)
    end
  end
end

