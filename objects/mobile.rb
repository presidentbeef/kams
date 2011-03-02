require 'objects/living'
require 'lib/reactor'
require 'traits/reacts'
require 'traits/respawns'

#Base class for all mobiles.
class Mobile < LivingObject
  include Reacts
  include Respawns

  def initialize(*args)
    super(*args)
    @short_desc = "A mobile stands here with a blank expression."
  end

  #Balance changes can be triggered in reaction files using the action 'balance'.
  #This will be triggered prior to setting the balance value, so
  #the event contains a :value key which will contain the future value while
  #the current value can still be accessed via self.balance.
  def balance= value
    self.alert(Event.new(Generic, :action => :balance, :value => value, :target => self))
    @balance = value
  end

  #Always returns false.
  def blind?
    false
  end

  #Always returns false.
  def deaf?
    false
  end

  def out_event event
    super
    if info.redirect_output_to
      if event[:target] == self and event[:player] != self
        self.output event[:to_target]
      elsif event[:player] == self
        self.output event[:to_player]
      else
        self.output event[:to_other]
      end
    end
  end

  #Generally a noop for Mobiles unless info.redirect_output_to has been
  #set to a given admin.
  def output(*args)
    if info.redirect_output_to
      out = $manager.get_object info.redirect_output_to

      if out
        out.output "[#{self.name} sees: #{args[0]}]"
      end
    end
  end

  #Show inventory in long_desc
  def long_desc
    desc = "" << super << "\r\n#{self.pronoun.capitalize} is holding "
    desc << @inventory.show << ".\r\n" <<  @equipment.show(self)

    return desc
  end

  def take_damage amount, type = :health
    super

    self.alert(Event.new(Generic, :action => :take_damage, :target => self, :amount => amount, :type => type))
  end
end
