require 'lib/gary'
require 'gdbm'
require 'digest/md5'
require 'thread'
require 'util/guid'
require 'util/log'
require 'lib/errors'
load 'util/all-behaviors.rb'
load 'util/all-objects.rb'

# Storage class for object persistance. Uses GDBM.
#
# GDBM is a file-system hash table which is fast and available on many
# platforms. However, it only stores strings. So objects are stored as Strings
# representing the marshaled object.
#
# The default storage system works this way: each GameObject is stored in a
# file which is named after the GameObject's class. For example, a Door would
# be in storage/Door. In each file, objects are indexed by their GOID. There
# is a special file in storage/goids which lists GOIDs and the class of the
# GameObject. This is used to find Objects according to their GOID.
#
# Here is an example: you want to load an object with a GOID of
# 476dfe3e-96bc-1952-fadd-26c22043a5a3. The StorageMachine will first open up
# storage/goids and retrieve the class pointed to by
# 476dfe3e-96bc-1952-fadd-26c22043a5a3, which happens to be Dog. The
# StorageMachine then opens up storage/Dog and again retrieves the Object
# pointed to by 476dfe3e-96bc-1952-fadd-26c22043a5a3, but this time it will be
# the (marshaled string of the) Dog object.
#
# Of course, there are exceptions. Players are handled differently, because
# they are typically looked up by name and not by their GOID. Instead of being
# listed in storage/goids, they are listed in storage/players. This file maps
# player names to GOIDs. Then they can be looked up by GOID in the
# storage/Player file. Additionally, passwords are stored as MD5 hashes in
# storage/passwords, indexed by GOID (a tiny bit of security there).
class StorageMachine
  def initialize(path = 'storage/')
    @path = path
    @mutex = Mutex.new
    @saved = 0
  end

  #This is the save function for a Player, since they need special handling.
  #
  #If password is something other than nil, then it saves the password. You
  #MUST DO THIS IF THIS IS A NEW PLAYER YOU ARE SAVING. OTHERWISE, the player
  #will be lost to you. Sorry!
  def save_player(player, password = nil)
    player_name = player.name.downcase
    open_store("players", false) do |gd|
      gd[player_name] = player.goid
    end
    unless password.nil?
      open_store("passwords", false) do |gd|
        gd[player.goid] = Digest::MD5.new.update(password).to_s
      end
    end

    #Yeah, so whatever on this little deal. Probably should do it better later.
    player.use_color = player.io.use_color if player.io
    player.color_settings = player.io.color_settings if player.io

    #Okay, this is tricky. We can't serialize the IO object stored in the Player
    #objects. To get around this (we don't want to store it anyhow), we temporarily
    #set it to nil, then back to whatever it was.
    player_connection = player.instance_variable_get(:@player)
    player.instance_variable_set(:@player, nil)

    log "Saving player: #{player.name}"
    store_object(player)

    player.inventory.each do |o|
      store_object(o)
    end

    log "Player saved: #{player.name}"
    player.instance_variable_set(:@player, player_connection)
  end

  #Sets password for a given player. Accepts player name or player object.
  def set_password(player, password)
    goid = nil
    name = nil
    if player.is_a? String
      name = player
    else
      name = player.name
    end

    open_store "players" do |gd|
      goid = gd[name.downcase]
    end

    open_store("passwords", false) do |gd|
      gd[goid] = Digest::MD5.new.update(password).to_s
    end
  end

  #Check if a player with the same name already exists in storage.
  def player_exist?(name)
    open_store "players" do |gd|
      gd.has_key? name.downcase
    end
  end

  #Returns the type of the object with the supplied goid
  def type_of goid
    open_store "goids" do |gd|
      type = gd[goid]
      if type
        Object.const_get type.to_sym
      else
        nil
      end
    end
  end

  #Looks up name, compares MD5 sum of password to the stored password,
  #and loads the player.
  def load_player(name, password, game_objects)
    goid = nil

    open_store "players" do |gd|
      goid = gd[name.downcase]
    end

    if goid.nil?
      log "Could not fetch player info #{name}"
      raise MUDError::UnknownCharacter
    end

    unless check_password name, password
      raise MUDError::BadPassword
    end

    log "Loading player...#{goid}"
    return load_object(goid, game_objects)
  end

  def check_password(name, password)
    stored_password = nil
    goid = nil
    open_store "players" do |gd|
      goid = gd[name.downcase]
    end
    open_store "passwords" do |gd|
      stored_password = gd[goid]
    end

    if stored_password.nil?
      log "Could not fetch password for #{name}"
      raise MUDError::UnknownCharacter
    end

    if Digest::MD5.new.update(password).to_s != stored_password
      log "Passwords did not match: #{stored_password} and #{Digest::MD5.new.update(password).to_s}"
      false
    else
      true
    end
  end

  #Deletes a character.
  def delete_player(name)
    name = name.downcase
    puts "Deleting player #{name}"

    goid = nil

    open_store("players", false) do |gd|
      goid = gd[name]
      gd.delete(name)
    end

    if goid.nil?
      puts "Could not fetch player info #{name}"
      return nil
    end

    open_store("passwords", false) do |gd|
      gd.delete goid
    end

    return delete_object(goid)
  end

  #Recursively stores object and its inventory.
  #
  #Warning: this temporarily removes the object's observers.
  def store_object(object)

    if object.is_a? Observable
      observers = object.instance_variable_get(:@observer_peers)
      unless observers.nil?
        observers = observers.dup
        object.delete_observers
      end
    end

    open_store("goids", false) do |gd|
      gd[object.goid] = object.class.to_s
    end

    open_store(object.class, false) do |gd|
      gd[object.goid] = Marshal.dump(object)
    end

    if object.is_a? Observable and not observers.nil?
      object.instance_variable_set(:@observer_peers, observers)
    end

    if object.respond_to? :equipment
      object.equipment.each do |o|
        store_object(o) unless o.is_a? Player #this shouldn't happen, but who knows
      end
    end

    @saved += 1

    log "Stored #{object} # #{object.game_object_id}", Logger::Ultimate
  end

  #Removes object from store. Object can be an actual GameObject or a GOID
  def delete_object(object)
    store = nil
    file = nil
    game_object_id = nil
    game_object = nil

    if not object.is_a? GameObject
      game_object_id = object

      open_store "goids" do |gd|
        file = gd[game_object_id]
      end

      if file.nil?
        log "No file found for that goid (#{game_object_id})"
        return nil
      end
    else
      game_object_id = object.game_object_id
      file = object.class.to_s
    end

    open_store(file, false) do |gd|
      gd.delete(game_object_id)
    end

    open_store("goids", false) do |gd|
      gd.delete(game_object_id)
    end
  end

  #Recursively loads an object and its inventory.
  def load_object(game_object_id, game_objects)
    object = nil
    file = nil

    open_store "goids" do |gd|
      file = gd[game_object_id]
    end

    if file.nil?
      log "No file found for that goid (#{game_object_id})"
      raise MUDError::NoSuchGOID
    end

    open_store file do |gd|
      object = Marshal.load(gd[game_object_id])
    end

    if object.nil?
      log "Tried to load object (#{game_object_id}), but got nil"
      raise MUDError::ObjectLoadError
    end

    if object.respond_to? :inventory
      log "Loading inventory for #{object}", Logger::Ultimate
      load_too = object.inventory
      object.inventory = Inventory.new(object.inventory.capacity)
      load_too.each do |goid|
        if game_objects.find_by_id(goid)
          obj = game_objects.find_by_id(goid)
        else
          obj = load_object(goid, game_objects)
        end

        #Don't want to load players until they are playing.
        #We can add the player to a room once they login, not before.
        object.inventory << obj unless obj.is_a? Player
        obj.container = object.goid
      end
    end

    if object.respond_to? :equipment
      log "Loading equipment for #{object}", Logger::Ultimate
      load_too = object.equipment.inventory
      object.equipment.inventory = Inventory.new
      load_too.each do |goid|
        if game_objects.find_by_id(goid)
          obj = game_objects.find_by_id(goid)
        else
          obj = load_object(goid, game_objects)
        end

        #Don't want to load players until they are playing.
        #We can add the player to a room once they login, not before.
        unless obj.is_a? Player or obj.nil?
          object.equipment.inventory << obj
          obj.info.equipment_of = object.goid
        end

        #Remove object if it does not seem to exist any longer
        if obj.nil?
          object.equipment.delete(goid)
        end
      end
    end

    if object.is_a? Observable
      fix_observers object
    end

    game_objects << object

    unless object.container.nil? or game_objects.loaded? object.container
      begin
        load_object(object.container, game_objects)
      rescue MUDError::NoSuchGOID, MUDError::ObjectLoadError
        object.container = ServerConfig.start_room
      end
    end
    return object
  end

  #Loads all GameObjects back into a Gary.
  #Except for players. Unless you want them.
  #
  #This method isn't very efficient. Sorry.
  def load_all(include_players = false, game_objects = nil)
    log "Loading all game objects...may take a while."
    files = {}
    objects = []
    game_objects ||= Gary.new

    log "Grabbing all the goids..."

    #Get which goids are in which files, so we can pull them out.

    open_store "goids" do |gd|
      gd.each_pair do |k,v|
        if files[v].nil?
          files[v] = [k]
        else
          files[v] << k
        end
      end
    end

    #Don't want to load players, unless specified that we do
    files.delete(Player) unless include_players

    #Load each object.
    files.each do |type, ids|
      open_store type do |gd|
        ids.each do |id|
          object = Marshal.load(gd[id])
          log "Loaded #{object}", Logger::Ultimate
          unless object.nil? or (not include_players and object.is_a? Player)
            if object.is_a? Observable
              fix_observers object
            end

            game_objects << object
            objects << object
          end
        end
      end
    end

    log "Loading inventories and equipment..."
    #Setup inventory and equipment for each one.
    objects.each do |obj|
      load_inv(obj, game_objects)
      load_equipment(obj, game_objects)
    end
    log "...done loading inventories and equipment."

    return game_objects
  end

  #Saves all objects in the game_objects Gary.
  #
  #This should mainly be used when the game exits,
  #as it briefly mutilates the objects.
  def save_all(game_objects)
    log "Saving given objects (#{game_objects.length})...please wait..."
    @saved = 0
    game_objects.each do |o|
      if o.is_a? Player
        save_player(o)
      else
        store_object(o)
      end
    end
    log "...done saving objects (#{@saved})."
  end

  #Open the store for the given type.
  def open_store(file, read_only = true)
    file = file.to_s
    if read_only
      flags = GDBM::READER
    else
      flags = GDBM::SYNC
    end
    @mutex.synchronize do
      GDBM.open(@path + file, 0666, flags) do |gd|
        yield gd
      end
    end
  end

  #Sets the inventory for the given object, out of the given
  #game objects.
  def load_inv(object, game_objects)

    if not object.respond_to? :inventory
      #log "#{object} has no inventory"
      return
    elsif object.inventory.nil?  #I can't think of when this might happen
      object.inventory = Inventory.new
      #log "#{object} had a nil inventory"
      return
    elsif object.inventory.empty?
      object.inventory = Inventory.new(object.inventory.capacity)
      #log "#{object} has nothing in its inventory"
      return
    end

    inv = Inventory.new(object.inventory.capacity)

    object.inventory.each do |inv_obj|
      if game_objects.include? inv_obj
        obj = game_objects[inv_obj]
        unless obj.is_a? Player
          inv.add(obj)
          obj.container = object.goid
        end
        #log "Added #{obj} to #{object}"
      else
        log "Don't have #{inv_obj} loaded...what does that mean? (Probably a Player)", Logger::Medium
      end
    end

    object.inventory = inv
  end

  #Sets the equipment for the given object, out of the given
  #game objects.
  def load_equipment(object, game_objects)

    if not object.respond_to? :equipment
      #log "#{object} has no equipment"
      return
    end

    load_inv(object.equipment, game_objects)
    object.equipment.each do |o|
      o.info.equipment_of = object.goid
    end
  end

  #THIS IS DANGEROUS
  #
  #THIS IS DANGEROUS - WHATEVER YOU DO, DO NOT RUN ON LIVE SERVER
  #
  #THIS IS DANGEROUS
  #
  #Each object will be loaded and passed into the block supplied.
  #You can do whatever you want to the object in that block.
  #Then whatever is returned will be saved and you can move on to the next object.
  #
  #THIS IS REALLY DANGEROUS
  def update_all_objects!
    load_all(true).each do |game_object|
      game_object = yield game_object
      store_object(game_object)
    end
  end

  #Fixes issue with changes with Observer between Ruby 1.8.7 and 1.9.1
  def fix_observers object
    if RUBY_VERSION < "1.9.0"
      object.instance_variable_set(:@observer_peers, [])
    else
      object.instance_variable_set(:@observer_peers, {})
    end
  end

  public :update_all_objects!
end

