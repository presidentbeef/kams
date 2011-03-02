require 'lib/gary'
require 'thread'

#This is a version of a Gary which will unload unused objects and reload them transparently. Unloading is currently
#only done by manually calling Gary#unload_extra().
#
#BUT IT IS CURRENTLY NOT USED AND PROBABLY NOT NEEDED ANYWAY.
class CacheGary < Gary

  def initialize(storage, manager)
    super()
    @all_goids = Set.new
    @storage = storage
    @manager = manager
  end

  #This function saves and unloads all objects with empty inventories and either no container, or
  #a container which has also been offloaded.
  def unload_extra
    log "Unloading extra baggage" , Logger::Ultimate
    @mutex.synchronize do
      @ghash.delete_if do |goid, obj|
        if obj.busy?
          log "#{obj} busy" , Logger::Ultimate
          false
        elsif obj.is_a? Player or obj.is_a? Mobile
          false
        elsif obj.container.nil? or not self.loaded? obj.container
          puts "Checking #{obj}" , Logger::Ultimate
          if obj.can? :inventory
            if obj.inventory.has_any? Player or obj.inventory.has_any? Mobile
              log "It contains a player or mobile:" , Logger::Ultimate
              log obj.inventory.find_all('class', Player) , Logger::Ultimate
              log obj.inventory.find_all('class', Mobile) , Logger::Ultimate
              false
            else
              @storage.store_object(obj)
              true
            end
          else
            log "Saving #{obj}" , Logger::Ultimate
            @storage.store_object(obj)
            log "Dropping #{obj}\nContainer is #{obj.container}\nNo Inventory" , Logger::Ultimate
            log "Saving #{obj}" , Logger::Ultimate
            true
          end
        else
          puts "#{obj} isn't a player or a mobile or busy and it has a container" , Logger::Ultimate
          false
        end
      end
    end
    log "Baggage unloaded", Logger::Ultimate
  end

  #Checks to see if a particular goid is currently in memory
  def loaded? goid
    !!@ghash[goid]
  end

  #Look up an object by goid.
  #This function is potentially dangerous, since it is not using a mutex
  def [] goid
    if @ghash[goid]
      return @ghash[goid]
    elsif @all_goids.include? goid
      log "Loading #{goid} from storage" , Logger::Ultimate
      begin
        obj = @storage.load_object(goid, self)
        obj.add_observer(@manager)
      rescue MUDError::NoSuchGOID
        log "Tried to load #{goid}, but it must have been deleted."
        return nil
      end
      return obj
    else
      return nil
    end
  end

  #Add object to CacheGary, also adds the Manager as an observer.
  def << game_object
    @mutex.synchronize do
      @ghash[game_object.goid] = game_object
      @all_goids << game_object.goid
      game_object.add_observer(@manager)
    end
  end

  #Delete object from CacheGary, and therefore from the game. Note, however, that this change
  #is not stored until shutdown (or whenever everything gets stored).
  def delete(object)
    obj = super(object)
    @all_goids.delete(obj.goid) if obj
  end
end
