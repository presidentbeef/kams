require 'objects/exit'
#Like an Exit, but different.
#
#Portals can be entered, do not show up on the list of exits,
class Portal < Exit

  #Creates a new portal. args same as Exit.
  def initialize(exit_room = nil, *args)
    super
    @generic = 'portal'
    @article = 'a'
    @visible = false
    @show_in_look = "A portal to the unknown stands here."
  end

  #Message when a player enters through the portal.
  #If info.entrance_message has not been set, provides a generic message.
  #
  #Otherwise, info.entrance_message can be used to create custom messages.
  #Use !name in place of the player's name.
  #
  #If something more complicated is required, override this method in a subclass.
  def entrance_message player, action = nil
    if info.entrance_message
      info.entrance_message.gsub(/(!name|!pronoun\(:(\w+)\)|!pronoun)/) do
        case $1
        when "!name"
          player.name
        when "!pronoun"
          player.pronoun
        else
          if $2
            player.pronoun($2.to_sym)
          end
        end
      end
    else
      case action
      when "jump"
        "#{player.name} jumps in over #{self.name}."
      when "climb"
        "#{player.name} comes in, climbing #{self.name}."
      when "crawl"
        "#{player.name} crawls in through #{self.name}."
      else
        "#{player.name} steps through #{self.name}."
      end
    end
  end

  #Message when leaving in the given direction. Works the same way as #entrance_message
  def exit_message player, action = nil
    if info.exit_message
      info.exit_message.gsub(/(!name|!pronoun\(:(\w+)\)|!pronoun)/) do
        case $1
        when "!name"
          player.name
        when "!pronoun"
          player.pronoun
        else
          if $2
            player.pronoun($2.to_sym)
          end
        end
      end
    else
      case action
      when "jump"
        "#{player.name} jumps over #{self.name}."
      when "climb"
        "#{player.name} climbs #{self.name}."
      when "crawl"
        "#{player.name} crawls out through #{self.name}."
      else
        "#{player.name} steps through #{self.name} and vanishes."
      end
    end
  end

  #The message sent to the player as they pass through the portal.
  def portal_message player, action = nil
    if info.portal_message
      info.portal_message.gsub(/(!name|!pronoun\(:(\w+)\)|!pronoun)/) do
        case $1
        when "!name"
          player.name
        when "!pronoun"
          player.pronoun
        else
          if $2
            player.pronoun($2.to_sym)
          end
        end
      end
    else
      case action
      when "jump"
        "Gathering your strength, you jump over #{self.name}."
      when "climb"
        "You reach up and climb #{self.name}."
      when "crawl"
        "You stretch out on your stomach and crawl through #{self.name}."
      else
        "You boldly step through #{self.name}."
      end
    end
  end

  def peer
    self.long_desc
  end
end
