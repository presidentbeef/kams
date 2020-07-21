require 'yaml'

#Used for the server config.
module ServerConfig

  class << self
    #Returns array of configuration keys.
    def options
      self.load.keys
    end

    #Returns an arbitrary configuration item.
    #
    # ServerConfig[:something]
    def [] item
      self.load[item]
    end

    #Sets a configuration value. Saves to file.
    def []= item, value
      self.load[item] = value
      self.save
      if item == :debug
        $DEBUG = value
      end
    end

    #Returns the name of the main admin.
    def admin
      self.load[:admin]
    end

    #Server address.
    def address
      self.load[:address]
    end

    #Checks if such a setting exists.
    def has_setting? setting
      self.load.has_key? setting
    end

    #File containing the text shown when someone logs on.
    def intro_file
      self.load[:intro_file]
    end

    #Returns the log level (as an Integer).
    def log_level
      self.load[:log_level]
    end

    #Server port.
    def port
      self.load[:port]
    end

    #How often to save the world state to disk, in minutes.
    #Recommended value would be once per day, 1440 minutes.
    def save_rate
      self.load[:save_rate]
    end

    #Returns the GOID of the room new characters
    #begin in.
    def start_room
      self.load[:start_room]
    end

    #Loads the configuration. Returns cached value unless force is true.
    def load(force = false)
      if force or not @config
        File.open "conf/config.yaml" do |f|
          @config = YAML.load(f)
        end

        $DEBUG = @config[:debug]
      end
      @config
    end

    #Returns the delay for server restart (in seconds)
    def restart_delay
      self.load[:restart_delay]
    end

    #Returns the number of restarts allowed before the server gives up.
    def restart_limit
      self.load[:restart_limit]
    end

    #Forces the configuration to be reloaded.
    def reload
      @config = self.load(true)
    end

    #Saves the configuration to file.
    def save
      File.open "conf/config.yaml", "w" do |f|
        YAML.dump(@config, f)
      end
    end

    #String representation.
    def to_s
      output = []
      @config.each do |k,v|
        output << "#{k}: #{v}"
      end
      output.join("\n")
    end

    #How often all the objects get updated, in seconds.
    def update_rate
      self.load[:update_rate]
    end
  end

end
