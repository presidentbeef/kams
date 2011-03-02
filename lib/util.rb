class Array

  #Joins the array into a simple list with commas and 'and'.
  #
  # ["dog", "cat", "cat", "fish"].simple_list => "dog, 2 cats, and fish"
  #
  # ["dog", "cat", "cat", "fish"].simple_list => "dog, cat, cat, and fish"
  def simple_list
    if self.length > 2
      "#{self[0..-2].join(', ')}, and #{self[-1]}"
    else
      self.join(" and ")
    end
  end

  #If supplied with an inventory, returns list with combined stacks of objects that are the same.
  #
  #Otherwise, the same as simple_list.
  def list(inventory = nil)
    return simple_list if not inventory
    if self.length < 2
      return self[0]
    end

    counts = Hash.new(0)

    self.each do |i|
      counts[i] += 1
    end

    counts.collect do |name, count|
      if count > 1
        ob = inventory.find(name)
        if ob.nil?
          "#{count} unknowns"
        else
          "#{count} #{ob.plural}"
        end
      else
        name
      end
    end.simple_list
  end
end

module Kernel

  #Returns the opposite direction. If no direction matches, returns dir.
  #
  # opposite_dir "west" => "east"
  # opposite_dir "u" => "down"
  # opposite_dir "around" => "around"
  def opposite_dir dir

    return dir unless dir.is_a? String

    case dir.downcase
    when "e", "east"
      "west"
    when "w", "west"
      "east"
    when "n", "north"
      "south"
    when "s", "south"
      "north"
    when "ne", "northeast"
      "southwest"
    when "se", "southeast"
      "northwest"
    when "sw", "southwest"
      "northeast"
    when "nw", "northwest"
      "southeast"
    when "up"
      "down"
    when "down"
      "up"
    when "in"
      "out"
    when "out"
      "in"
    else
      dir
    end
  end

  def expand_direction dir

    return dir unless dir.is_a? String

    case dir.downcase
    when "e", "east"
      "east"
    when "w", "west"
      "west"
    when "n", "north"
      "north"
    when "s", "south"
      "south"
    when "ne", "northeast"
      "northeast"
    when "se", "southeast"
      "southeast"
    when "sw", "southwest"
      "southwest"
    when "nw", "northwest"
      "northwest"
    when "u", "up"
      "up"
    when "d", "down"
      "down"
    when "i", "in"
      "in"
    when "o", "out"
      "out"
    else
      dir
    end
  end

  #Creates a future event and adds it to the EventHandler
  def after time, unit = :sec, event = nil, &block
    case unit
    when :sec
      seconds = time
    when :min
      seconds = time * 60
    when :hour
      seconds = time * 3600
    when :day
      seconds = time * 3600 * 24
    when :week
      seconds = time * 3600 * 24 * 7
    when :month
      seconds = time * 3600 * 24 * 7 * 30
    else
      seconds = time
    end

    if event
      f = CommandParser.future_event(self, seconds, event)

      if block_given?
        log "Ignoring block for future event."
      end
    else
      f = CommandParser.future_event(self, seconds, &block)
    end

    $manager.update f
    f
  end
end
