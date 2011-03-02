require 'set'

#Another outdated module. This should probably be replaced at some point.
module Sittable

  def initialize(*args)
    super
    @sitting_on_me = Set.new
    @sittable_occupancy = 1
  end

  def sittable?
    true
  end

  def occupied?
    not @sitting_on_me.empty?
  end

  def has_room?
    @sitting_on_me.length < @sittable_occupancy
  end

  #I find this module really humorous for some reason
  def sat_on_by object
    @sitting_on_me << object.goid
  end

  def occupants
    @sitting_on_me
  end

  def evacuated_by object
    @sitting_on_me.delete object.goid
  end

  def occupied_by? object
    @sitting_on_me.include? object.goid
  end
end
