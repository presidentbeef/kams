#Contains all the emote actions
module Emote
  class << self
    #Do an emote
    def emote(event, player, room)
      action = event[:show].strip

      unless ['!', '.', '?', '"'].include? action[-1..-1]
        action << '.'
      end

      if action =~ /\$me[^a-zA-Z]/i
        action.gsub!(/\$me/i, player.name)
        action[0,1] = action[0,1].capitalize
        show = action
      elsif action.include? '$'
        people = []
        action.gsub!(/\$(\w+)/) do |name|
          target = room.find($1)
          people << target unless target.nil?
          target ? target.name : 'no one'
        end

        people.each do |person|
          out = action.gsub(person.name, 'you')
          person.output("#{player.name} #{out}") unless person.can? :blind and person.blind?
        end

        room.output("#{player.name} #{action}", player, *people)
        player.output("You emote: #{player.name} #{action}")
      else
        show = "#{player.name} #{action}"
      end

      if show
        event.to_player = "You emote: #{show}"
        event.to_other = show
        room.out_event event
      end
    end

    #Smile
    def smile(event, player, room)

      make_emote event, player, room do

        self_target do
          to_player "You smile happily at yourself."
          to_other "#{player.name} smiles at #{player.pronoun(:reflexive)} sillily."
        end

        target do
          to_player "You smile at #{event.target.name} kindly."
          to_target "#{player.name} smiles at you kindly."
          to_other "#{player.name} smiles at #{event.target.name} kindly."
        end

        no_target do
          to_player "You smile happily."
          to_other "#{player.name} smiles happily."
        end
      end
    end

    def eh(event, player, room)
      make_emote event, player, room do
        target do
          to_player "After giving #{event.target.name} a cursory glance, you emit an unimpressed, 'Eh.'"
          to_other "#{player.name} gives #{event.target.name} a cursory glance and then emits an unimpressed, 'Eh.'"
          to_target "#{player.name} gives you a cursory glance and then emits an unimpressed, 'Eh.'"
        end

        no_target do
          to_player "After a brief consideration, you give an unimpressed, 'Eh.'"
          to_other "#{player.name} appears to consider for a moment before giving an unimpressed, 'Eh.'"
        end
      end
    end

    def eh?(event, player, room)

      make_emote event, player, room do
        no_target do
          to_player "Thoughtfully, you murmur, \"Eh?\""
          to_other "#{player.name} murmurs, \"Eh?\" with a thoughtful appearance."
        end

        target do
          to_player "Looking perplexed, you ask #{target.name}, \"Eh?\""
          to_other "\"Eh?\" #{player.name} asks #{target.name}, looking perplexed."
          to_target "\"Eh?\" #{player.name} asks you, with a perplexed expression."
        end
      end
    end

    def er(event, player, room)
      make_emote event, player, room do
        no_target do
          to_player "With a look of uncertainty, you say, \"Er...\""
          to_other "With a look of uncertainty, #{player.name} says, \"Er...\""
        end

        target do
          to_player "Looking at #{target.name} uncertainly, you say, \"Er...\""
          to_other "Looking at #{target.name} uncertainly, #{player.name} says, \"Er...\""
          to_target "Looking at you uncertainly, #{player.name} says, \"Er...\""
        end
      end
    end

    def uh(event, player, room)
      make_emote event, player, room do
        no_target do
          to_player "\"Uh...\" you say, staring blankly."
          to_other "With a blank stare, #{player.name} says, \"Uh...\""
        end

        target do
          to_player "With a blank stare at #{target.name}, you say, \"Uh...\""
          to_other "With a blank stare at #{target.name}, #{player.name} says, \"Uh...\""
          to_target "Staring blankly at you, #{player.name} says, \"Uh...\""
        end
      end
    end

    #Laugh laugh laugh
    def laugh(event, player, room)

      make_emote event, player, room do

        self_target do
          to_player "You laugh heartily at yourself."
          to_other "#{player.name} laughs heartily at #{player.pronoun(:reflexive)}."
          to_blind_other "Someone laughs heartily."
        end

        target do
          to_player "You laugh at #{event.target.name}."
          to_target "#{player.name} laughs at you."
          to_other "#{player.name} laughs at #{event.target.name}"
          to_blind_target "Someone laughs in your direction."
          to_blind_other "You hear someone laughing."
        end

        no_target do
          to_player "You laugh."
          to_other "#{player.name} laughs."
          to_blind_other "You hear someone laughing."
          to_deaf_other "You see #{player.name} laugh."
        end
      end

    end

    #Weepiness
    def cry(event, player, room)

      make_emote event, player, room do

        default do
          to_player "Tears run down your face as you cry pitifully."
          to_other "Tears run down #{player.name}'s face as #{player.pronoun} cries pitifully."
        end
      end
    end

    def skip(event, player, room)

      make_emote event, player, room do

        no_target do
          to_player "You skip around cheerfully."
          to_other "#{player.name} skips around cheerfully."
          to_deaf_other "#{player.name} skips around cheerfully."
        end

        self_target do
          player.output 'How?'
        end

        target do
          to_player "You skip around #{event.target.name} cheerfully."
          to_target "#{player.name} skips around you cheerfully."
          to_other "#{player.name} skips around #{event.target.name} cheerfully."
          to_deaf_other "#{player.name} skips around #{event.target.name} cheerfully."
        end

      end
    end

    def pet(event, player, room)

      make_emote event, player, room do

        no_target do
          player.output "Who are you trying to pet?"
        end

        self_target do
          to_player 'You pet yourself on the head in a calming manner.'
          to_other "#{player.name} pets #{player.pronoun(:reflexive)} on the head in a calming manner."
          to_deaf_other "#{player.name} pets #{player.pronoun(:reflexive)} on the head in a calming manner."
        end

        target do
          to_player "You pet #{event.target.name} affectionately."
          to_target "#{player.name} pets you affectionately."
          to_deaf_target event[:to_target]
          to_blind_target "Someone pets you affectionately."
          to_other "#{player.name} pets #{event.target.name} affectionately."
          to_deaf_other event[:to_other]
        end
      end
    end

    def nod(event, player, room)

      make_emote event, player, room do

        no_target do
          to_player "You nod your head."
          to_other "#{player.name} nods #{player.pronoun(:possessive)} head."
          to_deaf_other event[:to_other]
        end

        self_target do
          to_player 'You nod to yourself thoughtfully.'
          to_other "#{player.name} nods to #{player.pronoun(:reflexive)} thoughtfully."
          to_deaf_other event[:to_other]
        end

        target do

          to_player "You nod your head towards #{event.target.name}."
          to_target "#{player.name} nods #{player.pronoun(:possessive)} head towards you."
          to_other "#{player.name} nods #{player.pronoun(:possessive)} head towards #{event.target.name}."
          to_deaf_other event[:to_other]
        end
      end
    end

    def hug(event, player, room)

      make_emote event, player, room do

        no_target do
          player.output "Who are you trying to hug?"
        end

        self_target do
          to_player 'You wrap your arms around yourself and give a tight squeeze.'
          to_other "#{player.name} gives #{player.pronoun(:reflexive)} a tight squeeze."
          to_deaf_other event[:to_other]
        end

        target do
          to_player "You give #{event.target.name} a great big hug."
          to_target "#{player.name} gives you a great big hug."
          to_other "#{player.name} gives #{event.target.name} a great big hug."
          to_blind_target "Someone gives you a great big hug."
          to_deaf_other event[:to_other]
        end
      end
    end

    def grin(event, player, room)

      make_emote event, player, room do

        no_target do
          to_player 'You grin widely, flashing all your teeth.'
          to_other "#{player.name} grins widely, flashing all #{player.pronoun(:possessive)} teeth."
          to_deaf_other event[:to_other]
        end

        self_target do
          to_player "You grin madly at yourself."
          to_other "#{player.name} grins madly at #{event.target.pronoun(:reflexive)}."
          to_deaf_other event[:to_other]
        end

        target do
          to_player "You give #{event.target.name} a wide grin."
          to_target "#{player.name} gives you a wide grin."
          to_deaf_target event[:to_target]
          to_other "#{player.name} gives #{event.target.name} a wide grin."
          to_deaf_other event[:to_other]
        end

      end
    end

    def frown(event, player, room)

      make_emote event, player, room do
        no_target do
          to_player "The edges of your mouth turn down as you frown."
          to_other "The edges of #{player.name}'s mouth turn down as #{player.pronoun} frowns."
          to_deaf_other event[:to_other]
        end

        self_target do
          to_player "You frown sadly at yourself."
          to_other "#{player.name} frowns sadly at #{event.target.pronoun(:reflexive)}."
          to_deaf_other event[:to_other]
        end

        target do
          to_player "You frown at #{event.target.name} unhappily."
          to_target "#{player.name} frowns at you unhappily."
          to_deaf_target event[:to_target]
          to_other "#{player.name} frowns at #{event.target.name} unhappily."
          to_deaf_other event[:to_other]
        end
      end

    end

    def blush(event, player, room)

      make_emote event, player, room do

        no_target do
          to_player "You feel the blood rush to your cheeks and you look down, blushing."
          to_other "#{player.name}'s face turns bright red as #{player.pronoun} looks down, blushing."
          to_deaf_other event[:to_other]
        end

        self_target do
          to_player "You blush at your foolishness."
          to_other "#{player.name} blushes at #{event.target.pronoun(:possessive)} foolishness."
          to_deaf_other event[:to_other]
        end

        target do
          to_player "Your face turns red and you blush at #{event.target.name} uncomfortably."
          to_target "#{player.name} blushes in your direction."
          to_deaf_target event[:to_target]
          to_other "#{player.name} blushes at #{event.target.name}, clearly uncomfortable."
          to_deaf_other event[:to_other]
        end
      end
    end

    def ew(event, player, room)

      make_emote event, player, room do

        no_target do
          to_player "\"Ewww!\" you exclaim, looking disgusted."
          to_other "#{player.name} exclaims, \"Eww!!\" and looks disgusted."
          to_deaf_other "#{player.name} looks disgusted."
          to_blind_other "Somone exclaims, \"Eww!!\""
        end

        self_target do
          player.output "You think you are digusting?"
        end

        target do
          to_player "You glance at #{event.target.name} and say \"Ewww!\""
          to_target "#{player.name} glances in your direction and says, \"Ewww!\""
          to_deaf_other "#{player.name} gives #{event.target.name} a disgusted look."
          to_blind_other "Somone exclaims, \"Eww!!\""
          to_other "#{player.name} glances at #{event.target.name}, saying \"Ewww!\""
        end
      end
    end

    def snicker(event, player, room)

      make_emote event, player, room do

        no_target do
          to_player  "You snicker softly to yourself."
          to_other "You hear #{player.name} snicker softly."
          to_blind_other "You hear someone snicker softly."
        end

        self_target do
          player.output "What are you snickering about?"
        end

        target do
          to_player  "You snicker at #{event.target.name} under your breath."
          to_target "#{player.name} snickers at you under #{player.pronoun(:possessive)} breath."
          to_other "#{player.name} snickers at #{event.target.name} under #{player.pronoun(:possessive)} breath."
        end
      end

    end

    def wave(event, player, room)

      make_emote event, player, room do

        no_target do
          to_player  "You wave goodbye to everyone."
          to_other "#{player.name} waves goodbye to everyone."
        end

        self_target do
          player.output "Waving at someone?"
        end

        target do
          to_player  "You wave farewell to #{event.target.name}."
          to_target "#{player.name} waves farewell to you."
          to_other "#{player.name} waves farewell to #{event.target.name}."
        end
      end
    end

    def poke(event, player, room)

      make_emote event, player, room do

        no_target do
          player.output "Who are you trying to poke?"
        end

        self_target do
          to_player  "You poke yourself in the eye. 'Ow!'"
          to_other "#{player.name} pokes #{player.pronoun(:reflexive)} in the eye."
          to_deaf_other event[:to_other]
        end

        target do
          to_player  "You poke #{event.target.name} playfully."
          to_target "#{player.name} pokes you playfully."
          to_blind_target "Someone pokes you playfully."
          to_deaf_target event[:to_target]
          to_other "#{player.name} pokes #{event.target.name} playfully."
          to_deaf_other event[:to_other]
        end
      end
    end

    def yes(event, player, room)
      make_emote event, player, room do

        no_target do
          to_player  "\"Yes,\" you say, nodding."
          to_other "#{player.name} says, \"Yes\" and nods."
        end

        self_target do
          to_player  "You nod in agreement with yourself."
          to_other "#{player.name} nods at #{player.pronoun(:reflexive)} strangely."
          to_deaf_other event[:to_other]
        end

        target do
          to_player  "You nod in agreement with #{event.target.name}."
          to_target "#{player.name} nods in your direction, agreeing."
          to_other "#{player.name} nods in agreement with #{event.target.name}."
          to_deaf_other event[:to_other]
        end
      end

    end

    def no(event, player, room)
      make_emote event, player, room do
        no_target do
          to_player  "\"No,\" you say, shaking your head."
          to_other "#{player.name} says, \"No\" and shakes #{player.pronoun(:possessive)} head."
        end
        self_target do
          to_player  "You shake your head negatively in your direction. You are kind of strange."
          to_other "#{player.name} shakes #{player.pronoun(:possessive)} head at #{player.pronoun(:reflexive)}."
          to_deaf_other event[:to_other]
        end
        target do
          to_player  "You shake your head, disagreeing with #{event.target.name}."
          to_target "#{player.name} shakes #{player.pronoun(:possessive)} head in your direction, disagreeing."
          to_other "#{player.name} shakes #{player.pronoun(:possessive)} head in disagreement with #{event.target.name}."
          to_deaf_other event[:to_other]
        end
      end

    end

    def huh(event, player, room)
      make_emote event, player, room do

        no_target do
          to_player  "\"Huh?\" you ask, confused."
          to_other "#{player.name} ask, \"Huh?\" and looks confused."
        end

        self_target do
          player.output "Well, huh!"
        end

        target do
          to_player "\"Huh?\" you ask #{event.target.name}."
          to_target "#{player.name} asks, \"Huh?\""
          to_other "#{player.name} asks #{event.target.name}, \"Huh?\""
        end
      end

    end

    def hi(event, player, room)

      make_emote event, player, room do

        no_target do
          to_player "\"Hi!\" you greet those around you."
          to_other "#{player.name} greets those around with a \"Hi!\""
        end

        self_target do
          player.output "Hi."
        end

        target do
          to_player "You say \"Hi!\" in greeting to #{event.target.name}."
          to_target "#{player.name} greets you with a \"Hi!\""
          to_other "#{player.name} greets #{event.target.name} with a hearty \"Hi!\""
        end
      end

    end

    def bye(event, player, room)

      make_emote event, player, room do

        no_target do
          to_player "You say a hearty \"Goodbye!\" to those around you."
          to_other "#{player.name} says a hearty \"Goodbye!\""
        end

        self_target do
          player.output "Goodbye."
        end

        target do
          to_player "You say \"Goodbye!\" to #{event.target.name}."
          to_target "#{player.name} says \"Goodbye!\" to you."
          to_other "#{player.name} says \"Goodbye!\" to #{event.target.name}"
        end
      end

    end

    def yawn(event, player, room)

      make_emote event, player, room do

        no_target do
          to_player "You open your mouth in a wide yawn, then exhale loudly."
          to_other "#{player.name} opens #{player.pronoun(:possessive)} mouth in a wide yawn, then exhales loudly."
        end

        self_target do
          to_player "You yawn at how boring you are."
          to_other "#{player.name} yawns at #{player.pronoun(:reflexive)}."
          to_deaf_other event[:to_other]
        end

        target do
          to_player "You yawn at #{event.target.name}, bored out of your mind."
          to_target "#{player.name} yawns at you, finding you boring."
          to_other "#{player.name} yawns at how boring #{event.target.name} is."
          to_deaf_other event[:to_other]
        end
      end

    end

    def bow(event, player, room)

      make_emote event, player, room do

        no_target do
          to_player "You bow deeply and respectfully."
          to_other "#{player.name} bows deeply and respectfully."
          to_deaf_other event[:to_other]
        end

        self_target do
          player.output  "Huh?"
        end

        target do
          to_player  "You bow respectfully towards #{event.target.name}."
          to_target "#{player.name} bows respectfully before you."
          to_other "#{player.name} bows respectfully towards #{event.target.name}."
          to_deaf_other event[:to_other]
        end
      end

    end

    def curtsey(event, player, room)

      make_emote event, player, room do

        no_target do
          to_player  "You perform a very graceful curtsey."
          to_other "#{player.name} curtseys quite gracefully."
          to_deaf_other event[:to_other]
        end

        self_target do
          player.output "Hm? How do you do that?"
        end

        target do
          to_player "You curtsey gracefully and respectfully towards #{event.target.name}."
          to_target "#{player.name} curtseys gracefully and respectfully in your direction."
          to_other "#{player.name} curtseys gracefully and respectfully towards #{event.target.name}."
          to_deaf_other event[:to_other]
        end

      end
    end

    def ponder(event, player, room)

      make_emote event, player, room do

        no_target do
          to_player "You ponder that idea for a moment."
          to_other "#{player.name} looks thoughtful as #{player.pronoun} ponders a thought."
          to_deaf_other event[:to_other]
        end

        self_target do
          to_player  "You look down in deep thought at your navel."
          to_other "#{player.name} looks down thoughtfully at #{player.pronoun(:possessive)} navel."
          to_deaf_other event[:to_other]
        end

        target do
          to_player "You give #{event.target.name} a thoughtful look as you reflect and ponder."
          to_target "#{player.name} gives you a thoughtful look and seems to be reflecting upon something."
          to_other "#{player.name} gives #{event.target.name} a thoughtful look and appears to be absorbed in reflection."
          to_deaf_other event[:to_other]
        end
      end
    end

    def sigh(event, player, room)

      make_emote event, player, room do

        no_target do
          to_player "You exhale, sighing deeply."
          to_other "#{player.name} breathes out a deep sigh."
        end

        self_target do
          to_player "You sigh at your misfortunes."
          to_other "#{player.name} sighs at #{player.pronoun(:possessive)} own misfortunes."
        end

        target do
          to_player "You sigh in #{event.target.name}'s general direction."
          to_target "#{player.name} heaves a sigh in your direction."
          to_other "#{player.name} sighs heavily in #{event.target.name}'s direction."
        end
      end

    end

    def agree(event, player, room)

      make_emote event, player, room do

        no_target do
          to_player "You nod your head in agreement."
          to_other "#{player.name} nods #{player.pronoun(:possessive)} head in agreement."
          to_deaf_other event[:to_other]
        end

        self_target do
          to_player "You are in complete agreement with yourself."
          to_other "#{player.name} nods at #{player.pronoun(:reflexive)}, apparently in complete agreement."
          to_deaf_other event[:to_other]
        end

        target do
          to_player "You nod your head in agreement with #{event.target.name}."
          to_target "#{player.name} nods #{player.pronoun(:possessive)} head in agreement with you."
          to_other "#{player.name} nods #{player.pronoun(:possessive)} head in agreement with #{event.target.name}."
          to_deaf_other event[:to_other]
        end
      end

    end

    def shrug(event, player, room)

      make_emote event, player, room do

        no_target do
          to_player "You shrug your shoulders."
          to_other "#{player.name} shrugs #{player.pronoun(:possessive)} shoulders."
          to_deaf_other event[:to_other]
        end

        self_target do
          player.output "Don't just shrug yourself off like that!"

        end

        target do
          to_player  "You give #{event.target.name} a brief shrug."
          to_target "#{player.name} gives you a brief shrug."
          to_other "#{player.name} gives #{event.target.name} a brief shrug."
          to_deaf_other event[:to_other]
          to_deaf_target event[:to_target]
        end
      end

    end

    def brb(event, player, room)

      make_emote event, player, room do

        no_target do
          to_player "\"I shall return shortly!\" you say to no one in particular."
          to_other "#{player.name} says, \"I shall return shortly!\" to no one in particular."
          to_blind_other "Someone says, \"I shall return shortly!\""
        end

        self_target do
          player.output "Hm? How do you do that?"
        end

        target do
          to_player "You let #{event.target.name} know you will return shortly."
          to_target "#{player.name} lets you know #{player.pronoun} will return shortly."
          to_other "#{player.name} tells #{event.target.name} that #{player.pronoun} will return shortly."
          to_blind_other "Someone says, \"I shall return shortly!\""
        end
      end

    end

    def back(event, player, room)

      make_emote event, player, room do

        no_target do
          to_player "\"I'm back!\" you happily announce."
          to_other "\"I'm back!\" #{player.name} happily announces to those nearby."
          to_blind_other "Someone announces, \"I'm back!\""
        end

        self_target do
          player.output "Hm? How do you do that?"
        end

        target do
          to_player "You happily announce your return to #{event.target.name}."
          to_target "#{player.name} happily announces #{player.pronoun(:possessive)} return to you."
          to_other "#{player.name} announces #{player.pronoun(:possessive)} return to #{event.target.name}."
          to_blind_other "Someone says, \"I shall return shortly!\""
        end
      end
    end

    def cheer(event, player, room)

      make_emote event, player, room do

        no_target do
          to_player "You throw your hands in the air and cheer wildly!"
          to_other "#{player.name} throws #{player.pronoun(:possessive)} hands in the air as #{player.pronoun} cheers wildy!"
          to_blind_other "You hear someone cheering."
        end

        self_target do
          player.output "Hm? How do you do that?"
        end

        target do
          to_player "Beaming at #{event.target.name}, you throw your hands up and cheer for #{event.target.pronoun(:objective)}."
          to_target "Beaming at you, #{player.name} throws #{player.pronoun(:possessive)} hands up and cheers for you."
          to_other "#{player.name} throws #{player.pronoun(:possessive)} hands up and cheers for #{event.target.name}."
          to_blind_other "You hear someone cheering."
        end
      end
    end

    def hm(event, player, room)

      make_emote event, player, room do

        no_target do
          to_other "#{player.name} purses #{player.pronoun(:possessive)} lips thoughtfully and says, \"Hmmm...\""
          to_player "You purse your lips thoughtfully and say, \"Hmmm...\""
        end

        self_target do
          to_other "#{player.name} looks down at #{player.pronoun(:reflexive)} and says, \"Hmmm...\""
          to_player "You look down at yourself and say, \"Hmmm...\""
        end

        target do
          to_other "#{player.name} purses #{player.pronoun(:possessive)} lips as #{player.pronoun} looks thoughtfully at #{event.target.name} and says, \"Hmmm...\""
          to_player "You purse your lips as you look thoughtfully at #{event.target.name} and say, \"Hmmm...\""
          to_target "#{player.name} purses #{player.pronoun(:possessive)} lips as #{player.pronoun} looks thoughtfully at you and says, \"Hmmm...\""
        end
      end

    end

    private

    #Run an emote.
    def make_emote event, player, room, &block
      g = GenericEmote.new(event, player, room)
      g.instance_eval(&block)
      if g.return_event and g.return_event.is_a? Event
        g.set_post #add postfix
        log "Doing event" , Logger::Ultimate
        room.out_event g.return_event
      end
    end
  end

  #Provides little DSL to easily create emotes.
  class GenericEmote

    attr_reader :return_event

    def initialize(event, player, room)
      @event = event
      @player = player
      @room = room
      @post = event[:post]
      @object = nil
      @return_event = nil
      find_target
    end

    #If there is no target, return the given block.
    def no_target
      return if @return_event

      if @object.nil?
        @return_event = yield
      end
    end

    #If the target is the player, return the given block.
    def self_target
      return if @return_event

      if @object == @player
        @return_event = yield
      end
    end

    #If there is a target, return the given block.
    def target
      return if @return_event

      unless @object.nil?
        @return_event = yield
      end
    end

    #If nothing else matches, return the given block.
    def default
      @return_event = yield
    end

    #Provide output to show player.
    def to_player output
      @event.to_player = output
      @event
    end

    #Provide output to show others.
    def to_other output
      @event.to_other = output
      @event
    end

    #Provide output to show target.
    def to_target output
      @event.to_target = output
      @event
    end

    #Provide output to show blind others.
    def to_blind_other output
      @event.to_blind_other = output
      @event
    end

    #Provide output to show deaf others.
    def to_deaf_other output
      @event.to_deaf_other = output
      @event
    end

    #Provide output to show blind target.
    def to_blind_target output
      @event.to_blind_target = output
      @event
    end

    #Provide output to show deaf target.
    def to_deaf_target output
      @event.to_deaf_target = output
      @event
    end

    #Appends suffix to emote.
    def set_post
      return if not @post
      [:to_player, :to_other, :to_target, :to_blind_other, :to_blind_target, :to_deaf_other, :to_deaf_target].each do |t|
        if @return_event[t]
          if @return_event[t][-1,1] == "."
            @return_event[t][-1] = ""
          end

          if @post[0,1] == ","
            @return_event[t] << @post
          else
            @return_event[t] << " " << @post
          end

          unless ["!", "?", ".", "\"", "'"].include? @post[-1,1]
            @return_event[t] << "."
          end
        end
      end
    end

    private

    #Find target for emote.
    def find_target
      if @object.nil? and @event[:object]
        @object = @room.find(@event[:object]) || @player.search_inv(@event[:object])
        @event[:target] = @object
      end
    end
  end
end
