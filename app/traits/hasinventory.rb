require 'objects/inventory'

#This module should be used for objects which have an Inventory.
module HasInventory

  #Same arguments as the object.
  def initialize(*args)
    super
    @inventory = Inventory.new
  end

  #Searches inventory for an item. If item is not in inventory but object has equipment, search equipment, too.
  def search_inv item, type = nil
    object = @inventory.find(item, type)
    if object.nil? and self.can? :equipment
      object = @equipment.find(item)
    end
    object
  end

  #Returns the inventory.
  def inventory
    @inventory
  end

  #Sets the inventory.
  def inventory= something
    @inventory = something
  end
end
