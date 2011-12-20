require 'set'
require 'lib/event'

#CommandParser parses commands into commands for the event handler.
module CommandParser
  @generic_commands = Set.new([
  'bug',
  'date',
  'delete',
  'look',
  'l',
  'get',
  'take',
  'feel',
  'idea',
  'taste',
  'smell',
  'sniff',
  'lick',
  'listen',
  'grab',
  'give',
  'health',
  'hunger',
  'satiety',
  'i',
  'inv',
  'inventory',
  'more',
  'quit',
  'open',
  'close',
  'shut',
  'drop',
  'put',
  'help',
  'lock',
  'unlock',
  'status',
  'stat',
  'st',
  'time',
  'typo',
  'who',
  'write'
  ])

  @communication = Set.new([
  'say',
  'sayto',
  'whisper',
  'tell',
  'reply'
  ])

  @movement = Set.new([ 'go',
  'east',
  'e',
  'west',
  'w',
  'south',
  's',
  'north',
  'n',
  'up',
  'u',
  'down',
  'd',
  'northeast',
  'ne',
  'northwest',
  'nw',
  'southeast',
  'se',
  'southwest',
  'sw',
  'in',
  'out',
  'sit',
  'stand',
  'pose',
  'enter',
  'climb',
  'jump',
  'crawl',
  'gait'
  ])

  @emotes = Set.new([ 'smile',
  'cheer',
  'back',
  'laugh',
  'cry',
  'emote',
  'eh',
  'er',
  'eh?',
  'uh',
  'pet',
  'hug',
  'blush',
  'ew',
  'frown',
  'grin',
  'hm',
  'snicker',
  'wave',
  'poke',
  'yes',
  'no',
  'huh',
  'hi',
  'bye',
  'yawn',
  'bow',
  'curtsey',
  'brb',
  'agree',
  'sigh',
  'ponder',
  'shrug',
  'skip',
  'nod'
  ])

  @news = Set.new(['news'])

  @weapon_combat = Set.new(['wield', 'unwield', 'slash', 'block'])

  @martial_combat = Set.new(['punch', 'kick', 'dodge'])

  @magic = Set.new

  @equipment = Set.new(['wear', 'remove'])

  @admin = Set.new(['acreate',
  'alook',
  'adesc',
  'acarea',
  'acopy',
  'acomment',
  'acomm',
  'aconfig',
  'acportal',
  'ahelp',
  'portal',
  'aset',
  'aset!',
  'adelete',
  'aforce',
  'ahide',
  'ashow',
  'ainfo',
  'aput',
  'alist',
  'alearn',
  'areas',
  'ateach',
  'areload',
  'areact',
  'awho',
  'alog',
  'astatus',
  'acroom',
  'acexit',
  'acdoor',
  'acprop',
  'asave',
  'awatch',
  'deleteplayer',
  'restart',
  'terrain',
  'whereis'
  ])

  @settings = Set.new(['set'])

  @mobile = Set.new(['teach'])

  #etc...

  class <<self

    #Creates an event to occur in the future. The event can be an event generated with CommandParser.parse or a block to be executed
    #when the time elapses.
    #
    #If a block is given, the event parameter is ignored.
    def future_event(player, seconds_delay, f_event = nil, &block)
      event = Event.new(:Future, :player => player, :time => seconds_delay)

      if block_given?
        event.action = :call
        event.event = block
      else
        event.action = :event
        event.event = f_event
      end

      event
    end

    #Parses input into a hash that can be passed to the EventHandler.
    #Returns nil if the input cannot be parsed into a meaningful command.
    def parse(player, input)
      if input.nil?
        return nil
      end

      input = input.strip

      if input == "" or input.nil?
        return nil
      end

      command = input.split

      if command.empty?
        return nil
      else
        command = command[0].downcase
      end

      event = if @generic_commands.include? command
          parse_generic input
        elsif @emotes.include? command
          parse_emote input
        elsif @movement.include? command
          parse_movement input
        elsif @equipment.include? command
          parse_equipment input
        elsif @settings.include? command
          parse_settings input
        elsif @admin.include? command and player.admin
          parse_admin input
        elsif @weapon_combat.include? command
          parse_weapon_combat input
        elsif @martial_combat.include? command
          parse_martial_combat input
        elsif @communication.include? command
          parse_communication input
        elsif @news.include? command
          parse_news input
        elsif @mobile.include? command and player.is_a? Mobile
          parse_mobile command  ### implement me
        elsif input =~ /^alarm\s+([0-9]+)$/i
          after $1.to_i do
            player.output "***ALARM***"
          end
        elsif input =~ /^(\w+)\s+(.*)$/
          parse_custom input
        end

      unless event.nil?
        event.player = player
      end

      event
    end

    alias :create_event :parse

    private

    def parse_generic(input)
      e = case input
          when /^delete me please$/i
            { :action => :deleteme }
          when /^(l|look)$/i
            { :action => :look }
          when /^(l|look)\s+(in|inside)\s+(.*)$/i
            { :action => :look, :in => $3 }
          when /^(l|look)\s+(.*)$/i
            { :action => :look, :at => $2 }
          when /^lock\s+(.*)$/i
            { :action => :lock, :object => $1 }
          when /^unlock\s+(.*)$/i
            { :action => :unlock, :object => $1 }
          when /^(get|grab|take)\s+((\w+|\s)*)(\s+from\s+(\w+))/i
            { :action => :get, :object => $2.strip, :from => $5 }
          when /^(get|grab|take)\s+(.*)$/i
            { :action => :get, :object => $2.strip }
          when /^give\s+((\w+\s*)*)\s+to\s+(\w+)/i
            { :action => :give, :item => $2.strip, :to => $3 }
          when /^(i|inv|inventory)$/i
            { :action => :show_inventory }
          when /^more/i
            { :action => :more }
          when /^open\s+(\w+)$/i
            { :action => :open, :object => $1 }
          when /^(close|shut)\s+(\w+)$/i
            { :action => :close, :object => $2  }
          when /^drop\s+((\w+\s*)*)$/i
            { :action => :drop, :object => $1.strip }
          when /^quit$/i
            { :action => :quit }
          when /^put((\s+(\d+)\s+)|\s+)(\w+)\s+in\s+(\w+)$/i
            { :action => :put,
              :item => $4,
              :count => $3.to_i,
              :container => $5 }
          when /^help(.*)$/i
            { :action => :help, :object => $1 }
          when /^(health)$/i
            { :action => :health }
          when /^(satiety|hunger)$/i
            { :action => :satiety }
          when /^(st|stat|status)$/i
            { :action => :status }
          when /^write\s+(.*)/i
            { :action => :write, :target => $1.strip}
          when /^(listen|sniff|smell|taste|lick|feel)(\s+(.+))?$/i
            if $1.downcase == "sniff"
              action = :smell
            elsif $1.downcase == "lick"
              action = :taste
            else
              action = $1.downcase.to_sym
            end
            { :action => action, :target => $3}
          when /^(bug|typo|idea)\s+(\d+)\s+(show|del|add|status)(\s+(.+))?$/i
            { :action => :issue, :itype => $1.downcase.to_sym, :issue_id => $2, :option => $3.downcase, :value => $5 }
          when /^(bug|typo|idea)\s+(\d+)/i
            { :action => :issue, :itype => $1.downcase.to_sym, :option => "show", :issue_id => $2 }
          when /^(bug|typo|idea)\s+(del|add|show|status)\s+(\d+)(\s+(.+))?/i
            { :action => :issue, :itype => $1.downcase.to_sym, :option => $2.downcase, :issue_id => $3, :value => $5 }
          when /^(bug|typo|idea)\s+(new|show|del|add|status|list)(\s+(.+))?$/i
            { :action => :issue, :itype => $1.downcase.to_sym, :option => $2.downcase, :value => $4 }
          when /^(bug|typo|idea)\s+(.*)$/i
            { :action => :issue, :itype => $1.downcase.to_sym, :option => "new", :value => $2 }
          when /^who$/i
            { :action => :who }
          when /^time$/i
            { :action => :time }
          when /^date$/i
            { :action => :date }
          else
            nil
          end

      Event.new(:Generic, e) if e
    end

    def parse_communication(input)
      e = case input
          when /^say\s+(\((.*?)\)\s*)?(.*)$/i
            { :action => :say, :phrase => $3, :pre => $2 }
          when /^sayto\s+(\w+)\s+(\((.*?)\)\s*)?(.*)$/i
            { :action => :say, :target => $1, :phrase => $4, :pre => $3 }
          when /^whisper\s+(\w+)\s+(\((.*?)\)\s*)?(.*)$/i
            { :action => :whisper, :to => $1, :phrase => $4, :pre => $3 }
          when /^tell\s+(\w+)\s+(.*)$/i
            { :action => :tell, :target => $1, :message => $2 }
          when /^reply\s+(.*)$/i
            { :action => :reply, :message => $1 }
          else
            nil
          end

      Event.new(:Communication, e) if e
    end

    def parse_emote(input)
      event = Event.new(:Emote)

      case input
      when /^emote\s+(.*)/i
        event[:action] = :emote
        event[:show] = $1
      when /^(uh|er|eh\?|eh|shrug|sigh|ponder|agree|cry|hug|pet|smile|laugh|ew|blush|grin|frown|snicker|wave|poke|yes|no|huh|hi|bye|yawn|bow|curtsey|brb|skip|nod|back|cheer|hm)(\s+([^()]*))?(\s+\((.*)\))?$/i
        event[:action] = $1.downcase.to_sym
        event[:object] = $3
        event[:post] = $5
      else
        return nil
      end

      event
    end

    def parse_movement(input)
      event = Event.new(:Movement, :action => :move)

      case input
      when /^gait(\s+(.*))?$/i
        event[:action] = :gait
        event[:phrase] = $2 if $2
      when /^go\s+(.*)$/i
        event[:direction] = $1.downcase
      when /^(jump|climb|crawl|enter)\s+(.*)$/i
        event[:action] = :enter
        event[:portal_action] = $1.downcase
        event[:object] = $2
      when /^sit\s+on\s+(.*)$/i, /^sit\s+(.*)$/i, /^sit$/i
        event[:action] = :sit
        event[:object] = $1.strip if $1
      when /^pose\s+(.*)$/i
        event[:action] = :pose
        event[:pose] = $1.strip
      when /^stand$/i
        event[:action] = :stand
      when /^(jump|crawl|climb|enter)$/i
        input.downcase!
        return nil  ### TODO: handle portal movement
      when /^(east|west|northeast|northwest|north|southeast|southwest|south|e|w|nw|ne|sw|se|n|s|up|down|u|d|in|out)(\s+\((.*)\))?$/i
        event[:direction] = expand_direction $1
        event[:pre] = $3
      else
        return nil
      end

      event
    end

    def parse_equipment(input)
      event = Event.new(:Clothing)

      case input
      when /^wear\s+(\w+)(\s+on\s+(.*))?$/i
        event[:action] = :wear
        event[:object] = $1
        event[:position] = $3
      when /^remove\s+(\w+)(\s+from\s+(.*))?$/i
        event[:action] = :remove
        event[:object] = $1
        event[:position] = $3
      else
        return nil
      end

      event
    end

    def parse_admin(input)
      event = Event.new(:Admin)

      case input
      when /^astatus/i
        event[:action] = :astatus
      when /^ahelp(.*)$/i
        event[:action] = :ahelp
        event[:object] = $1
      when /^awho/i
        event[:action] = :awho
      when /^(ac|acreate)\s+(\w+)\s*(.*)$/i
        event[:action] = :acreate
        event[:object] = $2
        event[:name] = $3.strip
      when /^acarea\s+(.*)$/i
        event[:action] = :acarea
        event[:name] = $1.strip
      when /^acroom\s+(\w+)\s+(.*)$/i
        event[:action] = :acroom
        event[:out_dir] = $1
        event[:in_dir] = opposite_dir($1)
        event[:name] = $2
      when /^acexit\s+(\w+)\s+(.*)$/i
        event[:action] = :acreate
        event[:object] = "exit"
        event[:alt_names] = [$1.strip]
        event[:args] = [$2.strip]
      when /^acdoor\s+(\w+)$/i
        event[:action] = :acdoor
        event[:direction] = $1
      when /^acdoor\s+(\w+)\s+(.*)$/i
        event[:action] = :acdoor
        event[:direction] = $1.strip
        event[:exit_room] = $2.strip
      when /^aconfig(\s+reload)?$/i
        event[:action] = :aconfig
        event[:setting] = "reload" if $1
      when /^aconfig\s+(\w+)\s+(.*)$/i
        event[:action] = :aconfig
        event[:setting] = $1
        event[:value] = $2
      when /^acportal(\s+(jump|climb|crawl|enter))?(\s+(.*))?$/i
        event[:action] = :acportal
        event[:object] = "portal"
        event[:alt_names] = []
        event[:portal_action] = $2
        event[:args] = [$4]
      when /^portal\s+(.*?)\s+(action|exit|entrance|portal)\s+(.*)$/i
        event[:action] = :portal
        event[:object] = $1
        event[:setting] = $2.downcase
        event[:value] = $3.strip
      when /^acprop\s+(.*)$/i
        event[:action] = :acreate
        event[:object] = "prop"
        event[:generic] = $1
      when /^adelete\s+(.*)$/i
        event[:action] = :adelete
        event[:object] = $1
      when /^deleteplayer\s+(\w+)$/i
        event[:action] = :delete_player
        event[:object] = $1.downcase
      when /^adesc\s+inroom\s+(.*?)\s+(.*)$/i
        event[:action] = :adesc
        event[:object] = $1
        event[:inroom] = true
        event[:desc] = $2
      when /^adesc\s+(.*?)\s+(.*)$/i
        event[:action] = :adesc
        event[:object] = $1
        event[:desc] = $2
      when /^ahide\s+(.*)$/i
        event[:action] = :ahide
        event[:object] = $1
        event[:hide] = true
      when /^ashow\s+(.*)$/i
        event[:action] = :ahide
        event[:object] = $1
        event[:hide] = false
      when /^ainfo\s+set\s+(.+)\s+@((\w|\.|\_)+)\s+(.*?)$/i
        event[:action] = :ainfo
        event[:command] = "set"
        event[:object] = $1
        event[:attrib] = $2
        event[:value] = $4
      when /^ainfo\s+(del|delete)\s+(.+)\s+@((\w|\.|\_)+)$/i
        event[:action] = :ainfo
        event[:command] = "delete"
        event[:object] = $2
        event[:attrib] = $3
      when /^ainfo\s+(show|clear)\s+(.*)$/i
        event[:action] = :ainfo
        event[:object] = $2
        event[:command] = $1
      when /^alook$/i
        event[:action] = :alook
      when /^alook\s+(.*)$/i
        event[:action] = :alook
        event[:at] = $1
      when /^alist$/i
        event[:action] = :alist
      when /^alist\s+(@\w+|class)\s+(.*)/i
        event[:action] = :alist
        event[:attrib] = $2
        event[:match] = $1
      when /^aset\s+(.+?)\s+(@\w+|smell|feel|texture|taste|sound|listen)\s+(.*)$/i
        event[:action] = :aset
        event[:object] = $1
        event[:attribute] = $2
        event[:value] = $3
      when /^aset!\s+(.+?)\s+(@\w+|smell|feel|texture|taste|sound|listen)\s+(.*)$/i
        event[:action] = :aset
        event[:object] = $1
        event[:attribute] = $2
        event[:value] = $3
        event[:force] = true
      when /^aput\s+(.*?)\s+in\s+(.*?)$/i
        event[:action] = :aput
        event[:object] = $1
        event[:in] = $2
      when /^areas$/i
        event[:action] = :areas
      when /^areload\s+(.*)$/i
        event[:action] = :areload
        event[:object] = $1
      when /^areact\s+load\s+(.*?)\s+(\w+)$/i
        event[:action] = :areaction
        event[:object] = $1
        event[:command] = "load"
        event[:file] = $2
      when /^areact\s+(add|delete)\s+(.*?)\s+(\w+)$/i
        event[:action] = :areaction
        event[:object] = $2
        event[:command] = $1
        event[:action_name] = $3
      when /^areact\s+(reload|clear|show)\s+(.*?)$/i
        event[:action] = :areaction
        event[:object] = $2
        event[:command] = $1
      when /^alog\s+(\w+)(\s+(\d+))?$/i
        event[:action] = :alog
        event[:command] = $1
        event[:value] = $3.downcase if $3
      when /^acopy\s+(.*)$/i
        event[:action] = :acopy
        event[:object] = $1
      when /^alearn\s+(\w+)$/i
        event[:action] = :alearn
        event[:skill] = $1
      when /^ateach\s+(\w+)\s+(\w+)$/i
        event[:action] = :ateach
        event[:target] = $1
        event[:skill] = $2
      when /^aforce\s+(.*?)\s+(.*)$/i
        event[:action] = :aforce
        event[:target] = $1
        event[:command] = $2
      when /^(acomm|acomment)\s+(.*?)\s+(.*)$/i
        event[:action] = :acomment
        event[:target] = $2
        event[:comment] = $3
      when /^awatch\s+((start|stop)\s+)?(.*)$/i
        event[:action] = :awatch
        event[:target] = $3.downcase if $3
        event[:command] = $2.downcase if $2
      when /^asave$/i
        event[:action] = :asave
      when /^restart$/i
        event[:action] = :restart
      when /^terrain\s+area\s+(.*)$/i
        event[:action] = :terrain
        event[:target] = "area"
        event[:value] = $1
      when /^terrain\s+(room|here)\s+(type|indoors|underwater|water)\s+(.*)$/
        event[:action] = :terrain
        event[:target] = "room"
        event[:setting] = $2.downcase
        event[:value] = $3
      when /^whereis\s(.*)$/
        event[:action] = :whereis
        event[:object] = $1
      else
        return nil
      end

      event
    end

    def parse_settings(input)
      event = Event.new(:Settings)

      case input
      when /^set\s+colors?\s+(on|off|default)$/i
        event[:action] = :setcolor
        event[:option] = $1
      when /^set\s+colors?\s+(\w+)\s+(\w+)$/i
        event[:action] = :setcolor
        event[:option] = $1
        event[:color] = $2
      when /^set\s+colors?.*/i
        event[:action] = :showcolors
      when /^set\s+password$/i
        event[:action] = :setpassword
      when /^set\s+(\w+)\s*(.*)$/i
        event[:action] = :set
        event[:setting] = $1.strip
        event[:value] = $2.strip if $2
      else
        return nil
      end

      event
    end

    def parse_weapon_combat(input)
      event = Event.new(:WeaponCombat)

      case input
      when /^wield\s+(.*?)(\s+(\w+))?$/i
        event[:action] = :wield
        event[:weapon] = $1
        event[:side] = $3
      when /^unwield(\s+(.*))?$/i
        event[:action] = :unwield
        event[:weapon] = $2
      when /^slash$/i
        event[:action] = :slash
      when /^slash\s+(.*)$/i
        event[:action] = :slash
        event[:target] = $1
      when /^block(\s+(.*))?$/i
        event[:action] = :simple_block
        event[:target] = $2
      else
        return nil
      end

      event
    end

    def parse_custom(input)
      if input =~ /^(\w+)\s+(.*)$/
        event = Event.new(:Custom)
        event[:action] = :custom
        event[:custom_action] = $1
        event[:target] = $2
        event
      else
        nil
      end
    end

    def parse_news(input)
      event = Event.new(:News)

      case input.downcase
      when "news"
        event.action = :latest_news
      when /^news\s+last\s+(\d+)/i
        event.action = :latest_news
        event.limit = $1.to_i
      when /^news\s+(read\s+)?(\d+)$/i
        event.action = :read_post
        event.post_id = $2
      when /^news\s+write$/i
        event.action = :write_post
      when /^news\s+reply(\s+to\s+)?\s+(\d+)$/i
        event.action = :write_post
        event.reply_to = $2
      when /^news\s+delete\s+(\d+)/i
        event.action = :delete_post
        event.post_id = $1
      when /^news\s+unread/i
        event.action = :list_unread
      when /^news\s+all/i
        event.action = :all
      else
        return nil
      end

      event
    end

    def parse_martial_combat(input)
      event = Event.new(:MartialCombat)

      case input
      when /^punch$/i
        event.action = :punch
      when /^punch\s+(.*)$/i
        event.action = :punch
        event.target = $1
      when /^kick$/i
        event.action = :kick
      when /^kick\s+(.*)$/i
        event.action = :kick
        event.target = $1
      when /^dodge(\s+(.*))?$/i
        event.action = :simple_dodge
        event.target = $2 if $2
      else
        return nil
      end

      event
    end
  end
end
