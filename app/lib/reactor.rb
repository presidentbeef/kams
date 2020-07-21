require 'util/rproc'

#The Reactor class is the mechanism by which Mobiles can be scripted. A reaction is made up of three parts:
#* The action(s)/commands to which to react
#* A test (converts to a Proc) which returns true if the reaction should occur, false otherwise
#* A reaction (converts to a Proc) which will be run if the test is true (and the return value is run through CommandParser)
#
#The test and the reaction will be put in a lambda which will be passed the event and then used with mob.instance_eval:
#
# lambda { |event, mob| mob.instance_eval { /* Your code here */ } }
#
#A reaction looks something like this:
# reaction = { :action => :say,   #action to match
#              :test => "event[:player].name == 'Bob'", #this gets converted to a Proc and should return a boolean
#        :reaction => '"say I like Bob!"' #this gets converted to a Proc and run through a CommandParser as well
#   }
#
#Action can also be an Array, in which case it will match on any of them:
#
# reaction = { :action => [:hug, :kiss],
#        :test => "object_is_me? event",
#        :reaction => '"say Yuck! No snuggly stuff for me!"'
#   }
#
#Reactions can also be loaded from a plain text file from objects/reactions/[name].rx
#
#The format is the following:
#
# #This is a comment (must be at beginning of line)
# !action
# <space separated list of actions to trigger it>
# !test
# <test code>
# !reaction
# <reaction code>
#
#Example:
#
# #This is the same as the reaction above
# !action
# hug kiss
# !test
# object_is_me? event
# !reaction
# "say Yuck! No snuggly stuff for me!"
#
#There can be multiple reactions per file. !action signals the start of a new reaction and must be first. !test and !reaction can be in any order and
#can be any number of lines.
#
class Reactor

  #This initializes the Reactor, as you might expect
  def initialize(mob)
    @mob = mob
    @reactions = Hash.new
  end

  #Empty reaction
  def blank_reaction
    reaction = {
      :action => nil,
      :test => "",
      :reaction => ""
    }
  end

  private :blank_reaction

  #Loads reaction file from the path objects/reactions/{file}.rx
  def load(file)
    current_item = nil
    reaction = nil
    input = nil

    File.open("objects/reactions/#{file}.rx") do |f|
      until f.eof?
        input = f.gets

        case input.strip
        when "!action"
          self.add(reaction) unless reaction.nil?
          reaction = blank_reaction
          current_item = :action
        when "!test"
          current_item = :test
        when "!reaction"
          current_item = :reaction
        when /^#/
        when ""
        else
          if current_item == :action
            actions = input.split.map do |item|
              item.to_sym
            end
            if actions.size == 1
              reaction[:action] = actions[0]
            else
              reaction[:action] = actions
            end
          else
            reaction[current_item] += input
          end
        end
      end
      self.add(reaction) unless reaction.nil?
    end
  end

  #Adds a bunch of reactions, in some kind of Enumerable
  def add_all(reactions)
    reactions.each do |r|
      self.add(r)
    end
  end

  #Adds a single reaction
  def add(reaction)
    if reaction[:action] and reaction[:test] and reaction[:reaction] #validate
      reaction[:test] = RProc.new(reaction[:test])
      reaction[:reaction] = RProc.new(reaction[:reaction])

      if reaction[:action].is_a? Enumerable
        actions = reaction[:action]
      else
        actions = [reaction[:action]]
      end

      actions.each do |action|
        if @reactions[action].nil?
          @reactions[action] = [reaction]
        else
          @reactions[action] << reaction
        end
      end
      log "Added #{reaction.inspect}"
    else
      log "Not accepting reaction: #{reaction.inspect}" , Logger::Ultimate
    end
  end

  #Reacts to an event
  #
  #All matching reactions will fire. However, conditions are tested before any actions
  #are executed. Order of executions is nondeterministic.
  def react_to(event)
    log "Maybe reacting to #{event}" , Logger::Ultimate
    actions = []
    commands = []
    player = event[:player] || @mob
    room = $manager.get_object(@mob.room)
    begin
      unless @reactions[event[:action]].nil?
        @reactions[event[:action]].each do |r|
          if r[:test][event, player, room, @mob]
            log "Reacting" , Logger::Ultimate
            actions << r[:reaction]
            #break #breaking would mean only one reaction fires, even if many match
          end
        end
        log "No other tests passed for that action." , Logger::Ultimate
      else
        log "No reaction for that action." , Logger::Ultimate
      end

      actions.each do |a|
        begin
          result = a[event, player, room, @mob]
        rescue Exception => e
          log "Reaction error. #{@mob.name} reacting to #{event[:action]}: #{e.message}"
        end

        if result and result.is_a? String and result != ""
          commands << result
        end
      end
    rescue Exception => e
      log "#{e.inspect}\n#{e.backtrace.join("\n")}"
      return nil
    end

    commands
  end

  #Returns Array of reactions in this Reactor.
  def list_reactions
    seen = Set.new
    @reactions.collect do |k,v|
      a = v.collect do |r|
        if seen.include? r.object_id
        else
          seen << r.object_id
          "Action: #{(r[:action].is_a? Array) ? r[:action].join(", ") : r[:action] }\nTest: #{r[:test].source}Reaction:\n#{r[:reaction].source}"
        end
      end.compact
      a.empty? ? nil : a
    end.compact.join("\n")
  end

  #Deletes all of the reactions.
  def clear
    @reactions.clear
  end

  def to_s
    "Reactor (#{@reactions.length} reactions)"
  end
end
