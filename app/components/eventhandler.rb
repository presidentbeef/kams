require 'util/all-events'

#The Manager passes events through a queue to the EventHandler, which then executes the events according to the type and action of the Event.
#This is done by matching the type to a module defined in the events/ directory and calling the method with the name of the action.
class EventHandler
  attr_accessor :event_queue

  #Pass in Gary to EventHandler so EventRunner can have it.
  def initialize(game_objects)
    @event_queue = Queue.new
    @running = true
    @mutex = Mutex.new
  end

  #Empties the event Queue, then the thread sleeps. Gets woken up by the Manager.
  def run
    return unless @mutex.try_lock
    until @event_queue.empty? or not @running
      if @event_queue.length > 1
        log "#{@event_queue} events in queue", Logger::Medium
      end
      handle_event(@event_queue.pop)
    end
    @mutex.unlock
  end

  #Stops processing events.
  def stop
    @running = false
  end

  #Resumes processing events.
  def start
    @running = true
  end

  #Dispatches an event.
  def handle_event event
    return if not @running
    if not event.is_a? Event
      log "Invalid Event! Needs to be an Event, not a #{event.class}."
      return
    end

    events = [event]

    if event.attached_events
      events += get_attached(event)
    end

    events.each do |e|
      if e.player and e.type and e.action
        player = e.player
        room = $manager.find(player.room)
        #Replace 'me' with player's goid
        if e.at == 'me'
          e.at = player.goid
        elsif e.object == 'me'
          e.object = player.goid
        elsif e.target == 'me'
          e.target = player.goid
        end

        if e.type == :Future
          $manager.future_event e
        else
          begin
            Module.const_get(e.type).send(e.action, e, player, room)
          rescue NameError => exp
            log "Error when running event: #{exp}"
            log exp.backtrace
          rescue Exception => exp
            log exp
            log exp.backtrace
          end
        end
      else
        log "[Error] Mal-formed event: #{e}"
      end
    end
  end

  private

  def get_attached event
    events = []
    if event.attached_events
      events += event.attached_events
      event.attached_events.each do |e|
        events += get_attached(e)
      end
    end
    events
  end
end
