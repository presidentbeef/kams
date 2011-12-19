require 'traits/hasinventory'

#Holds an object's equipment, such as clothing, armor, weapons, etc.
#
#Some functions are kind of odd about what they return, so check carefully.
class Equipment
  include HasInventory

  @@slots = [
    :left_arm,
    :right_arm,
    :head,
    :face,
    :neck,
    :left_wrist,
    :right_wrist,
    :waist,
    :left_foot,
    :right_foot,
    :left_hand,
    :right_hand,
    :left_ring_finger,
    :right_ring_finger,
    :left_ear,
    :right_ear,
    :left_ankle,
    :right_ankle,
    :torso,
    :arms,
    :legs,
    :feet,
    :hands
    ]

  attr_reader :equipment

  #Creates a new Equipment object. Pass in the GOID of the object it will
  #be used with.
  def initialize(player_goid, *args)
    super(*args)
    @player = player_goid
    @equipment = {}
  end

  #This is weird, but it works out, I think.
  def goid
    @player
  end

  #Checks if the given item is being worn or wielded or neither.
  def worn_or_wielded? item
    object = @inventory.find item
    return false if object.nil?

    pos = position_of object

    return false if object.nil?

    if [:left_wield, :right_wield, :dual_wield].include? pos
      return "You will need to unwield #{object.name} first."
    else
      return "You will need to remove #{object.name} first."
    end
  end

  #Takes string "left", "right", "dual"
  def get_wielded(hand = nil)
    if hand
      case hand
      when "left"
        hand = :left_wield
      when "right"
        hand = :right_wield
      when "dual"
        hand = :dual_wield
      else
        return get_wielded
      end

      item = ((@equipment[hand] && @equipment[hand][0]))
    else
      item = ((@equipment[:left_wield] and @equipment[:left_wield][0]) || (@equipment[:right_wield] and @equipment[:right_wield][0]) || (@equipment[:dual_wield] and @equipment[:dual_wield][0]))
    end

    if item
      @inventory[item]
    else
      nil
    end
  end

  #Returns an array of all wielded items.
  def get_all_wielded
    ["left", "right", "dual"].collect do |w|
      get_wielded(w)
    end.compact
  end

  #If the given item can be wielded, returns nil.
  #Otherwise, returns a message for the player.
  def check_wield(item, position = nil)
    if position
      position = sym(position)
    else
      position = item.position
    end

    case position
    when :left_wield
      if get_wielded("left")
        return "You are already wielding something in that hand."
      elsif get_wielded("dual")
        return "You are wielding a two-handed weapon already."
      end
    when :right_wield
      if get_wielded("right")
        return "You are already wielding something in that hand."
      elsif get_wielded("dual")
        return "You are wielding a two-handed weapon already."
      end
    when :wield
      if get_wielded("left") && get_wielded("right")
        return "You need an empty hand."
      elsif get_wielded("dual")
        return "You are wielding a two-handed weapon already."
      end
    when :dual_wield
      if get_wielded
        return "You need both hands to be empty."
      end
    else
    end

    nil
  end

  #Put on an item in a position or the first place it fits.
  #
  #Returns nil upon failure.
  def wear(item, position = nil)
    if position
      position = sym(position)
    else
      position = item.position
    end

    position = find_empty_position(item, position)

    return nil if position.nil?

    container = $manager.get_object(item.container)

    if container and not container.is_a? Player
      container.remove(item)
    end

    item.container = nil

    @equipment[position] ||= []
    @equipment[position][item.layer] = item.goid
    @inventory << item
    item.info.equipment_of = @player
  end

  #Remove an item.
  #
  #Be sure to put the item in something or else it will be wandering out in space.
  def remove(item)
    pos = position_of(item)
    if pos
      @inventory.remove(item)
      @equipment[pos][item.layer] = nil
      item.info.delete_field :equipment_of
      item.container = @player
      true
    else
      false
    end
  end

  #Just remove it foreva
  def delete(goid)
    if goid.is_a? GameObject
      goid = goid.goid
    end

    @inventory.delete goid

    @equipment.each do |k,v|
      v.delete(goid) if v
    end
  end

  #Find an object by name.
  def find(item_name)
    @inventory.find(item_name)
  end

  #Find the position of a given object or if it is at a given position.
  #
  #Returns nil if the object can't be found.
  def position_of(game_object, position = nil)
    position ||= game_object.position
    position = sym(position)

    if [:arm, :leg, :wield, :wrist, :foot, :ankle, :ring_finger, :ear, :hand].include? position
      return position_of(game_object, "left_#{position}".to_sym) || position_of(game_object, "right_#{position}".to_sym)
    end

    if @equipment[position] and @equipment[position][game_object.layer] == game_object.goid
      return position
    else
      return nil
    end
  end

  #Iterate over the equipment.
  def each(&block)
    @inventory.each(&block)
  end

  #Returns a String of what the equipment looks like.
  def show(wearer = "You")
    if wearer == "You"
      pronoun = "You"
      output = ["You are wearing:"]
    else
      pronoun = wearer.pronoun
      output = ["#{pronoun.capitalize} is wearing:"]
    end

    wearing = []
    @@slots.each do |slot|
      line = show_position(slot, wearer)
      wearing << line if line
    end

    if wearing.empty?
      if pronoun == "You"
        (show_wielding(wearer) << "You are wearing nothing at all.").join("\n")
      else
        (show_wielding(wearer) << "#{pronoun.capitalize} is wearing nothing at all.").join("\n")
      end
    else
      (show_wielding(wearer) + output + wearing).join("\n")
    end
  end

  #Show the equipment at a given position.
  def show_position(position, wearer = "You")

    if wearer == "You"
      eq = @equipment[position]
      eq = eq.compact if eq
      if eq and not eq.empty?
        eq = eq.collect {|o| @inventory[o].name }.simple_list
        "\t#{eq} on your #{nice(position)}."
      else
        nil
      end

    else
      eq = @equipment[position]
      if eq
        item = nil
        eq[1..-1].each do |o|
          if o
            item = o
            break
          end
        end

        if item and eq[0]
          "\t#{@inventory[eq[0]].name} over #{@inventory[item].name} on #{wearer.pronoun(:possessive)} #{nice(position)}."
        elsif item
          "\t#{@inventory[item].name} on #{wearer.pronoun(:possessive)} #{nice(position)}."
        elsif eq[0]

          "\t#{@inventory[eq[0]].name} on #{wearer.pronoun(:possessive)} #{nice(position)}."
        else
          nil
        end
      else
        nil
      end
    end

  end

  #Show what the object is wielding.
  def show_wielding(wearer = "You")
    pronoun = nil
    output = nil
    if wearer == "You"
      output = "You are wielding "
      pronoun = "your"
    else
      output = "#{wearer.pronoun.capitalize} is wielding "
      pronoun = wearer.pronoun(:possessive)
    end

    wielding = []
    [:dual_wield, :left_wield, :right_wield].each do |pos|
      if @equipment[pos] and @equipment[pos][0]
        wielding << "#{@inventory[@equipment[pos][0]].name} in #{pronoun} #{nice(pos)}"
      end
    end

    if wielding.empty?
      if wearer == "You"
        output = ["You are not wielding anything."]
      else
        output = ["#{wearer.pronoun.capitalize} is not wielding anything."]
      end
    else
      [output << wielding.simple_list << "."]
    end
  end

  #Needs better error handling
  def [] position
    @equipment[position]
  end

  #Check if a position is free.
  #
  #Returns nil if it is, a message for the player if it is not.
  def check_position(item, position = nil)
    position = sym(position) unless position.nil?

    if not item.is_a? Wearable
      return "You cannot wear #{item.name}."
    elsif position.nil?
      position = item.position
    elsif position != item.position
      return "You cannot wear #{item.name} on your #{nice(position)}. It is intended to be worn on the #{nice(item.position)}."
    end

    if [:arm, :leg, :wield, :wrist, :foot, :ankle, :ring_finger, :ear, :hand].include? position
      return check_position(item, "left_#{position}".to_sym) && check_position(item, "right_#{position}".to_sym)
    end

    if @equipment[position].nil?
      return nil
    end

    if @equipment[position][item.layer].nil?
      return nil
    else
      if position.to_s.include? "wield"
        return "You are wielding #{@inventory[@equipment[position][item.layer]].name} there."
      else
        return "You are wearing #{@inventory[@equipment[position][item.layer]].name} where #{item.name} would be worn."
      end
    end
  end

  private

  #Turns position into a nice String
  def nice(position)
    if position == :left_wield
      "left hand"
    elsif position == :right_wield
      "right hand"
    elsif position == :dual_wield
      "both hands"
    elsif position == :wield
      "a hand"
    else
      position.to_s.gsub(/_/, ' ')
    end
  end

  #Turns a String into a Symbol
  def sym(position)
    return position if position.is_a? Symbol
    position.gsub(/\s/, '_').to_sym
  end

  #Finds the first empty position for an item.
  #
  #Returns nil if none are found.
  def find_empty_position(item, position)

    if [:arm, :leg, :wield, :wrist, :foot, :ankle, :ring_finger, :ear, :hand].include? position
      return find_empty_position(item, "left_#{position}".to_sym) || find_empty_position(item, "right_#{position}".to_sym)
    end

    if @equipment[position] and @equipment[position][item.layer]
      nil
    else
      position
    end
  end

  def to_s
    "Equipment for #{@player}"
  end
end
