require 'thread'
require 'set'

#The Gary (Game ARraY) is basically a nearly thread-safe set. Since it's only nearly thread-safe, be careful.
#The main purpose of this is to have a nice big ol' container of game objects that can be shared across threads and manager objects.
class Gary
  include Enumerable

  #Creates a new Gary.
  def initialize
    @mutex = Mutex.new
    @ghash = Hash.new
  end

  #Gets the quantity of each object type currently in the Gary.
  def type_count
    type_count = {}
    self.each do |go|
      if type_count[go.class].nil?
        type_count[go.class] = 1
      else
        type_count[go.class] += 1
      end
    end
    return type_count
  end

  #Returns true if length/size is zero.
  def empty?
    return self.length == 0
  end

  #Add a new object to the list of game objects.
  def << game_object
    @mutex.synchronize do
      @ghash[game_object.game_object_id] = game_object
    end
  end

  #Creates a duplicate of the Gary and runs the block for each member
  #of the duplicate to avoid blocking stuff but to also keep stuff
  #from getting too messed up, although it is still possible
  def each
    begin
      @ghash.dup.each_value do |go|
        yield go
      end
    rescue Exception => e
      log "Exception occured while iterating the (duplicate list of) members of this Gary"
      log e
      log e.inspect
      log e.backtrace.join("\n")
    end
  end

  #Look up a game object by its game_object_id (aka: goid). Returns the object or nil if it's not found.
  def [] game_object_id
    @mutex.synchronize do
      return @ghash[game_object_id]
    end
  end

  #Object can be an game object id or a game object. Deletes it from the game object set.
  def delete(object)
    if object.is_a?(GameObject)
      object_id = object.game_object_id
    else
      object_id = object
      object = find_by_id(object_id)
    end

    @mutex.synchronize do
      game_object = @ghash.delete(object_id)
    end
  end

  #Returns the number of objects in the set.
  def length
    return @ghash.length
  end

  #Checks name against name, alternate names, and generic names for each item and returns the first match or nil if none.
  #If type is other than nil, then it checks for that as well. (object.is_a? type)
  def find_by_generic(name, type = nil)
    if name.nil?
      return nil
    elsif not name.is_a? String
      name = name.to_s
    end

    name.downcase!
    @ghash.dup.each_value do |o|
      if type.nil?
        if o.generic.downcase == name or o.name.downcase == name or o.alt_names.find {|n| n.downcase == name }
          return o
        end
      else
        if o.is_a? type and (o.generic.downcase == name or o.name.downcase == name or o.alt_names.find {|n| n.downcase == name })
          return o
        end
      end
    end

    return nil
  end

  #First does find_by_id and then find_by_generic. Since find_by_generic also does find_by_name, you are all set.
  #This is probably the most useful of the find functions, if you ask me.
  #Note that find_by_id and find_by_name do not use the type comparison, only find_by_generic.
  def find(item, type = nil)
    find_by_id(item) || find_by_generic(item, type)
  end

  #Returns an array of all objects with attributes 'attrib' matching 'match'
  #
  #Match is converted thusly:
  # "129373" => 129373
  # "nil" => nil
  # "true" => true
  # "false" => false
  # ":hi" => :hi
  def find_all(attrib, match)
    results = []
    if attrib == "class" and not (match.is_a? Class or match.is_a? Module)
      match = Module.const_get(match.to_sym) rescue NameError
    end
    case match
    when "nil"
      match = nil
    when "true"
      match = true
    when "false"
      match = false
    when /^\d+$/
      match = match.to_i
    when /^:/
      match = match[1..-1].to_sym
    end
    if attrib == "class" and (match.is_a? Class or match.is_a? Module)
      @ghash.dup.each do |goid, obj|
        results << obj if obj.is_a? match
      end
    elsif match.is_a? String
      match.downcase!
      @ghash.dup.each do |goid, obj|
        if obj.instance_variables.include? attrib or obj.instance_variables.include? attrib.to_sym
          var = obj.instance_variable_get(attrib.to_sym)
          if var.is_a? String and var.downcase == match
            results << obj
          end
        end
      end
    else
      @ghash.dup.each do |goid, obj|
        results << obj if (obj.instance_variables.include? attrib or obj.instance_variables.include? attrib.to_sym) and obj.instance_variable_get(attrib.to_sym) == match
      end
    end
    results
  end

  #Finds an object by its goid.
  def find_by_id(goid)
    self[goid]
  end

  alias :remove :delete
  alias :add :<<
  alias :count :length

  #Returns true if the Gary contains the given object (name, id, generic, or actual game object).
  def include? object
    !!find(object)
  end

  #Checks if any objects of the given Class are in the Gary.
  def has_any? klass
    not find_all("class", klass).empty?
  end

end
