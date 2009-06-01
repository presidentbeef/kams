#Mixing in this module will allow any GameObject to react to events.
module Reacts

	def initialize(*args)
		super
		init_reactor
	end

	#Checks if a given object uses the reactions stored in a given file.
	def uses_reaction? file
		@reactions_files.include? file
	end

	#This is called when the object is created, but if the
	#module is mixed in dynamically this needs to be called before being used
	def init_reactor
		@reactor ||= Reactor.new(self)
		@reaction_files = Set.new
	end

	#Clears out current reactions and loads the ones
	#which have previously been loaded from a file.
	def reload_reactions
		@reactor.clear
		if @reaction_files
			@reaction_files.each do |file|
				load_reactions file
			end
		end
	end	

	#Deletes all reactions but does not clear the list of reaction files.
	def unload_reactions
		@reactor.clear if @reactor
		@reaction_files.clear if @reaction_files
	end

	#Loads reactions from a file.
	#
	#Note: This appends them to the existing reactions. To reload,
	#use Mobile#reload_reactions
	def load_reactions file
		@reaction_files ||= Set.new
		@reaction_files << file
		@reactor.load(file)
	end

	#Respond to an event by checking it against registered reactions.
	def alert(event)
		log "Got an alert about #{event}", Logger::Ultimate
		log "I am #{self.goid}", Logger::Ultimate
		reactions = @reactor.react_to(event)
		unless reactions.nil?
			reactions.each do |reaction|
				log "I am reacting...#{reaction.inspect}", Logger::Ultimate
				action = CommandParser.parse(self, reaction)
				unless action.nil?
					log "I am doing an action...", Logger::Ultimate 
					changed
					notify_observers(action)
				else
					log "Action did not parse: #{action}", Logger::Medium
				end
			end
		else
			log "No Reaction to #{event}", Logger::Ultimate
		end
	end

	#Returns a String representation of the reactions this GameObject has.
	def show_reactions
		if @reactor
			@reactor.list_reactions
		else
			"Reactor is nil"
		end
	end

	#Determines if the object of an event is this object.
	#
	#Mainly for use in reaction scripts.
	def object_is_me? event
		event[:target] == self
	end
end
