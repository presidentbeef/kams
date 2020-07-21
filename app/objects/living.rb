require 'lib/gameobject'
require 'objects/equipment'
require 'traits/position'
require 'traits/hasinventory'

#Shared parent class of Player and Mobile.
class LivingObject < GameObject
  include Position
  include HasInventory

  attr_reader :equipment, :balance
  attr_accessor :last_target, :alive

  def initialize *args
    super
    @equipment ||= Equipment.new(self.goid)
    @balance = true
    @alive = true
    @last_target = nil
    info.stats ||= Info.new
    info.stats.health = 100
    info.stats.max_health = 100
  end

  #Wear an item of clothing. Same as Player#wear
  def wear(item, position = nil)
    result = @equipment.check_position(item, position)

    if result
      self.output(result)
      return false
    end

    result = @equipment.wear(item, position)

    if result
      @inventory.remove(item)
      true
    else
      false
    end
  end

  #Removes an item of clothing and puts it in the Inventory.
  def remove(item, position = nil)
    result = @equipment.remove(item)

    if result
      @inventory.add(item)
      true
    else
      false
    end
  end

  #Takes damage.
  def take_damage amount, type = :health
    case type
    when :health
      info.stats.health and info.stats.health -= amount
      if info.stats.health < 0
        info.stats.health = 0
      end
    when :stamina
      info.stats.stamina and info.stats.stamina -= amount
      if info.stats.stamina < 0
        info.stats.stamina = 0
      end
    when :fortitude
      info.stats.fortitude and info.stats.fortitude -= amount
      if info.stats.fortitude < 0
        info.stats.fortitude = 0
      end
    else
      log "Do not know this kind of damage: #{type}"
    end

    alert Event.new(:Generic, :action => :take_damage, :type => type, :amount => amount)
  end

  #Returns the death message for this object.
  def death_message
    if info.death_message
      info.death_message
    else
      "The last bit of spark fades from #{name}'s eye as #{pronoun} slumps to the ground."
    end
  end
end
