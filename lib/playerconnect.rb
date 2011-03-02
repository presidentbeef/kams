require 'strscan'
require 'lib/ansicolor'
require 'lib/telnetcodes'
require 'socket'
require 'lib/errors'
require 'lib/login'
require 'lib/koapaginator'
require 'lib/editor'

#This is the network connection to the Player. Handles all input/output.
module PlayerConnection
  include Login
  include Editor

  #Input buffer
  attr_reader :in_buffer
  attr_accessor :color_settings, :use_color, :word_wrap

  #Default colors
  @@colors = {
      "black" => Color.black,
      "red" => Color.red,
      "green" => Color.green,
      "yellow" => Color.yellow,
      "blue" => Color.blue,
      "magenta" => Color.magenta,
      "cyan" => Color.cyan,
      "white" => Color.white,
      "brightred" => (Color.red + Color.bold),
      "brightgreen" => (Color.green + Color.bold),
      "brightyellow" => (Color.yellow + Color.bold),
      "brightblue" => (Color.blue + Color.bold),
      "brightmagenta" => (Color.magenta + Color.bold),
      "brightcyan" => (Color.cyan + Color.bold),
      "brightwhite" => (Color.white + Color.bold),
      "none" => Color.reset
    }

  #Set up everything
  def post_init
    @in_buffer = []
    @paginator = nil
    @color_settings = color_settings || to_default
    @use_color = true
    @mccp_to_client = false
    @mccp_from_client = false
    @word_wrap = 80
    @closed = false
    @state = :server_menu
    @login_name = nil
    @login_password = nil
    @password_attempts = 0
    @player = nil
    @expect_callback = nil
    @ip_address = Socket.unpack_sockaddr_in(self.get_peername)[1]

    print File.read(ServerConfig.intro_file) if File.exist? ServerConfig.intro_file

    echo_on

    ask_mssp if ServerConfig[:mssp]

    ask_mccp if ServerConfig[:mccp]

    show_server_menu

    log "Connection from #{@ip_address}."
  end

  #Returns setting for how long output should be before pagination.
  def page_height
    @player.page_height
  end

  #The next input will be passed to the given block.
  def expect(&block)
    @expect_callback = block
  end

  def ask question, &block
    self.output question
    self.expect do |answer|
       block.call answer
    end
  end

  def ask_menu options, answers = nil, &block
    @player.output options
    self.expect do |answer|
      if answers and not answers.include? answer
        player.menu options, answers, &block
      else
        block.call answer
      end
    end
  end

  #Connection closed
  def unbind
    File.open("logs/player.log", "a") { |f| f.puts "#{Time.now} - #{@player ? @player.name : "Someone"} logged out (#{@ip_address})." }
    log "#{@player ? @player.name: "Someone"} logged out (#{@ip_address}).", Logger::Ultimate
    @closed = true
    @mccp_to_client.finish if @mccp_to_client
    after 3 do
      if @player and $manager.object_loaded? @player.goid
        log "Connection broken, forcing manager to drop #{@player and @player.name}.", Logger::Medium
        $manager.drop_player(@player)
      end
      nil
    end
  end

  def send_data message
    message = compress message if @mccp_to_client
    super message
  end

  #Sets colors to defaults
  def to_default
    @use_color = true
    @color_settings = {
      "roomtitle" => "brightcyan",
      "roomdesc" => "cyan",
      "objects" => "magenta",
      "people" => "green",
      "exits" => "magenta",
      "say" => "brightwhite",
      "tell" => "cyan",
      "important" => "brightyellow",
      "editor" => "cyan",
      "news" => "brightcyan",
      "regular" => "none"
    }
  end

  #Checks if the io connection is nil or closed
  def closed?
    @closed
  end

  #Sends message followed by a newline. Also capitalizes
  #the first letter in the message.
  def puts message
    message = message.to_s
    first = message.index(/[a-zA-Z]/)
    message[first,1] = message[first,1].capitalize unless first.nil?
    self.print(message, true, true)
  end

  alias :output :puts
  alias :say :puts

  #Output an array of messages
  def put_list *messages
    messages.each { |m| self.puts m }
  end

  #Choose your pick
  def choose(prompt, *choices)
  end

  #Send message without newline
  def print(message, parse = true, newline = false)
    unless closed?
      if parse
        colorize message
        message.gsub!(/\t/, '     ')
        message = paginate(message)
      end
      if newline and message[-1..-1] != "\n"
        if message[-2..-2] == "\r"
          message << "\n"
        else
          message << "\r\n"
        end
      end
      message = @@colors[@color_settings["regular"]] + message + Color.clear
      send_data message
    end
  end

  def paginate message
    if @player.nil?
      return line_wrap(message)
    elsif not @player.page_height
      return line_wrap(message)
    #elsif not @word_wrap
      #return message.gsub(/([^\r]?)\n/, '\1' + "\r\n")
    end

    ph = @player.page_height

    out = []
    message = message.gsub(/((\e\[\d+m|[^\r\n\n\s\Z]){#@word_wrap})/, "\\1 ") if @word_wrap
    message.scan(/((((\e\[\d+m)|.){1,#{@word_wrap}})(\r\n|\n|\s+|\Z))|(\r\n|\n)/) do |m|
      if $2
        out << $2
      else
        out << ""
      end
    end

    if out.length < ph
      return out.join("\r\n")
    end

    @paginator = KPaginator.new(self, out)
    @paginator.more
  end

  #Only use if there is no line height
  def line_wrap message
    message = message.gsub(/((\e\[\d+m|[^\r\n\n\s\Z]){#{@word_wrap}})/, "\\1 ") if @word_wrap
    message.gsub(/(((\e\[\d+m)|.){1,#{@word_wrap}})(\r\n|\n|\s+|\Z)/, "\\1\r\n")
  end

  #Next page of paginated output
  def more
    if @paginator and @paginator.more?
      self.print(@paginator.more, false)
      if not @paginator.more?
        @paginator = nil
      end
    else
      @paginator = nil
      self.puts "There is no more."
    end
  end

  #Sets the colors in the string according to the player's preferences.
  def colorize string
    colors = @color_settings.keys.join("|")
    if @use_color
      string.gsub!(/<(#{colors})>/i) do |setting|
        @@colors[@color_settings[$1.downcase]]
      end
      string.gsub!(/<\/([^>]*)>/, @@colors[@color_settings["regular"]])
      #string.gsub!(/(\"(.*?)")/, @color_settings["quote"] + '\1' + @color_settings["regular"])
    else
      string.gsub!(/<(#{colors})>/i, "")
      string.gsub!(/<\/([^>]*)>/, "")
    end
  end

  #Sets the foreground color for a given setting.
  def set_fg_color(code, color)
    code.downcase! unless code.nil?
    color.downcase! unless color.nil?

    if not @color_settings.has_key? code
      "No such setting: #{code}"
    elsif not @@colors.has_key? color
      "Invalid color."
    else
      if not @use_color
        @color_settings.keys.each do |setting|
          @color_settings[setting] = Color.clear
        end
        @use_color = true
      end

      @color_settings[code] = color
      "Set #{code} to <#{code}>#{color}</>."
    end
  end

  #Returns list of color settings to show the player
  def show_color_config
  <<-CONF
Colors are currently: #{@use_color ? "Enabled" : "Disabled"}
Text                Setting          Color
-----------------------------------------------
Room Title          roomtitle        <roomtitle>#{@color_settings['roomtitle']}</roomtitle>
Room description    roomdesc         <roomdesc>#{@color_settings['roomdesc']}</roomdesc>
Objects             objects          <objects>#{@color_settings['objects']}</objects>
People              people           <people>#{@color_settings['people']}</people>
Exits               exits            <exits>#{@color_settings['exits']}</exits>
Say                 say              <say>#{@color_settings['say']}</say>
Tell                tell             <tell>#{@color_settings['tell']}</tell>
Important           important        <important>#{@color_settings['important']}</important>
Editor              editor           <editor>#{@color_settings['editor']}</editor>
News                news             <news>#{@color_settings['news']}</news>
Regular             regular          #{@color_settings['regular']}
CONF

  end

  #Close the io connection
  def close
    close_connection_after_writing
  end

  #Ask the client to stop echoing user input.
  #This is typically used for hiding passwords.
  def echo_off
    send_data IAC + WILL + OPT_ECHO
  end

  #Ask the client to start echoing user input.
  #Usually you would want echoing on.
  def echo_on
    send_data IAC + WONT + OPT_ECHO
  end

  def ask_mccp
    send_data IAC + WILL + OPT_COMPRESS2
  end

  def ask_mssp
    send_data IAC + WILL + OPT_MSSP
  end

  def send_mssp
    mssp_options = nil
    options = IAC + SB + OPT_MSSP

    if File.exist? "conf/mssp.yaml"
      File.open "conf/mssp.yaml" do |f|
        mssp_options = YAML.load(f)
      end

      mssp_options.each do |k,v|
        options << (MSSP_VAR + k + MSSP_VAL + v.to_s)
      end
    end

    options << (MSSP_VAR + "PLAYERS" + MSSP_VAL + $manager.find_all("class", Player).length.to_s)
    options << (MSSP_VAR + "UPTIME" + MSSP_VAL + $manager.uptime.to_s)
    options << (MSSP_VAR + "ROOMS" + MSSP_VAL + $manager.find_all("class", Room).length.to_s)
    options << (MSSP_VAR + "AREAS" + MSSP_VAL + $manager.find_all("class", Area).length.to_s)
    options << (MSSP_VAR + "ANSI" + MSSP_VAL + "1")
    options << (MSSP_VAR + "FAMILY" + MSSP_VAL + "CUSTOM")
    options << (MSSP_VAR + "CODEBASE" + MSSP_VAL + "KAMS " + $KAMS_VERSION)
    options << (MSSP_VAR + "PORT" + MSSP_VAL + ServerConfig.port.to_s)
    options << (MSSP_VAR + "MCCP" + MSSP_VAL + (ServerConfig[:mccp] ? "1" : "0"))
    options << (IAC + SE)
    send_data options
  end

  #Use zlib to compress message (for MCCP)
  def compress message
    begin
      @mccp_to_client.deflate message, Zlib::SYNC_FLUSH
    rescue Zlib::DataError
      message
    end
  end

  #Use zlib to decompress message (for MCCP)
  def decompress message
    p message
    #message =  "\x78\x01" + message

    begin
      Zlib::Inflate.inflate message
    rescue Zlib::DataError
      message
    end
  end

  #Pulled straight out of standard net/telnet lib.
  #Orginal version by Wakou Aoyama <wakou@ruby-lang.org>
  def preprocess_input string
    if @mccp_from_client
      string = decompress string
    end
    # combine CR+NULL into CR
    string = string.gsub(/#{CR}#{NULL}/no, CR)

      # combine EOL into "\n"
      string = string.gsub(/#{EOL}/no, "\n")

      string.gsub!(/#{IAC}(
        [#{IAC}#{AO}#{AYT}#{DM}#{IP}#{NOP}]|
        [#{DO}#{DONT}#{WILL}#{WONT}]
    [#{OPT_BINARY}-#{OPT_COMPRESS2}#{OPT_EXOPL}]|
    #{SB}[^#{IAC}]*#{IAC}#{SE}
    )/xno) do
      if    IAC == $1  # handle escaped IAC characters
        IAC
      elsif AYT == $1  # respond to "IAC AYT" (are you there)
        send_data("nobody here but us pigeons" + EOL)
        ''
      elsif DO == $1[0,1]  # respond to "IAC DO x"
        if OPT_BINARY == $1[1,1]
          send_data(IAC + WILL + OPT_BINARY)
        elsif OPT_MSSP == $1[1,1]
          send_mssp
        elsif OPT_COMPRESS2 == $1[1,1] and ServerConfig[:mccp]
          begin
            require 'zlib'
            send_data(IAC + SB + OPT_COMPRESS2 + IAC + SE)
            @mccp_to_client = Zlib::Deflate.new
          rescue LoadError
            log "Warning: No zlib - cannot do MCCP"
            send_data(IAC + WONT + $1[1..1])
            return
          end

        else
          #send_data(IAC + WONT + $1[1..1])
        end
        ''
      elsif DONT == $1[0,1]  # respond to "IAC DON'T x" with "IAC WON'T x"
        if OPT_COMPRESS2 == $1[1,1]
          @mccp_to_client = false
          send_data(IAC + WONT + $1[1..1])
        end
        ''
      elsif WILL == $1[0,1]  # respond to "IAC WILL x"
        if OPT_BINARY == $1[1,1]
          send_data(IAC + DO + OPT_BINARY)
        elsif OPT_ECHO == $1[1,1]
          send_data(IAC + DO + OPT_ECHO)
        elsif OPT_SGA  == $1[1,1]
          send_data(IAC + DO + OPT_SGA)
        elsif OPT_COMPRESS2 == $1[1,1]
          send_data(IAC + DONT + OPT_COMPRESS2)
        else
          send_data(IAC + DONT + $1[1..1])
        end
        ''
      elsif WONT == $1[0,1]  # respond to "IAC WON'T x"
        if OPT_ECHO == $1[1,1]
          send_data(IAC + DONT + OPT_ECHO)
        elsif OPT_SGA  == $1[1,1]
          send_data(IAC + DONT + OPT_SGA)
        elsif OPT_COMPRESS2 == $1[1,1]
          @mccp_from_client = false
          send_data(IAC + DONT + OPT_COMPRESS2)
        else
          send_data(IAC + DONT + $1[1..1])
        end
        ''
      else
        ''
      end
    end
    return string
  end
end
