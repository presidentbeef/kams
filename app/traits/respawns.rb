#This module allows Mobiles to respawn after they die.
module Respawns

  def initialize *args
    super
    if @container
      info.respawn_area = @container
    end
    info.respawn_rate = 900
    info.respawn_time = nil
  end

  def run
    super
    if !alive and info.respawn_time and Time.now.to_i > info.respawn_time
      respawn
    end
  end

  #Set the respawn time to the given number of seconds into the future.
  def respawn_in seconds
    info.respawn_time = (Time.now + seconds).to_i
  end

  private

  def respawn
    info.respawn_time = nil #Reset

    if info.respawn_area.nil?
      log "Cannot respawn! No info.respawn_area set."
      return
    end

    if info.respawn_area.is_a? Enumerable
      areas = info.respawn_area.to_a
      area = $manager.get_object areas[rand(areas.length)]
    else
      area = $manager.get_object info.respawn_area
    end

    case area
    when Area
      rooms = area.inventory.to_a
      room = $manager.get_object area.inventory.to_a[rand(rooms.length)]
    when Room
      room = area
    when Container
      room = area
    when Enumerable
      room = $manager.get_object area.inventory
    else
      log "Cannot find respawn area #{info.respawn_area} - not respawning."
      return
    end

    if room.nil?
      log "Cannot find respawn area #{room} - not respawning."
      return
    end

    add_event Event.new(:Mobiles, :player => self, :action => :respawn, :room => room)
  end
end
