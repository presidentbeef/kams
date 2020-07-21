#Erases and resets manager.

here = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH << here << "."

require "gdbm"
require "fileutils"
require "config"
require "log"
require "#{here}/../lib/util"
require "#{here}/../components/manager"

def log *args

end

def setup_menu
  loop do
    puts "", "-" * 30
    puts "WARNING: Do not use this setup script while KAMS is running!"
    puts "-" * 30
    puts "\nSetup Options for the Kingdoms of Ahln MUD Server:\n"
    puts ["1. Initial setup", "2. Initialize/reset storage", "3. Delete a player", "4. Change password", "5. Change GOID type", "6. Configuration options", "7. Exit"].join("\n")
    print "? "

    choice = gets.strip.to_i

    case choice
    when 1
      initial_setup
    when 2
      reset_storage
    when 3
      delete_player
    when 4
      change_password
    when 5
      change_goid
    when 6
      config_options
    when 7
      exit
    end
  end
end

def initial_setup
  puts "\nThis option will walk you through a few steps to set up the server."
  puts "\nSetting up storage..."
  reset_storage
  puts "\nSetting up initial configuration..."
  initial_options
end

def initial_options
  puts "\nNOTE: Press RETURN to keep current value!", ""
  print "Administrator login (currently #{ServerConfig[:admin]}): "
  name = gets.strip.downcase
  print "Port number (currently #{ServerConfig[:port]}): "
  port = gets.strip.to_i
  print "Address (currently #{ServerConfig[:address]}): "
  address = gets.strip

  ServerConfig[:admin] = name unless name.empty?
  ServerConfig[:port] = port unless port == 0
  ServerConfig[:address] = address unless address.empty?

  puts "-" * 20
  puts "Administrator login set to: #{ServerConfig[:admin]}"
  puts "Port number set to: #{ServerConfig[:port]}"
  puts "Address set to: #{ServerConfig[:address]}", "-" * 20
end

def reset_storage

  print "\nThis will erase all data and storage.\nAre you SURE you wish to do this (yes/no)? "

  answer = gets.chomp

  if answer !~ /^y/i
    puts "!! - Not doing it."
    return
  end

  puts "Erasing storage..."
  FileUtils.rm_rf "storage/", :secure => true
  FileUtils.mkdir "storage"
  FileUtils.mkdir "storage/boards"
  FileUtils.mkdir "storage/admin"
  FileUtils.mkdir "logs" if not File.exist? "logs/"

  puts "Recreating storage structure..."

  ["passwords", "players", "goids"].each do |f|
    GDBM.open "storage/#{f}" do |g|
      g.fastmode = false
      g.clear
      g.reorganize
    end
  end

  puts "Recreating initial objects..."

  $manager = Manager.new
  $manager.create_object(Room, nil, nil, :@name => "GarbageRoom")
  area = $manager.create_object(Area, nil, nil, :@name => "an Expansive Wilderness")
  area.info.terrain.area_type = :grassland
  room = $manager.create_object(Room, area, nil,  :@name => "A wide-open field", :@short_desc => "Endless possibilities stretch out to the horizon.")
  room.info.terrain.room_type = :grassland
  ServerConfig[:start_room] = room.goid
  man = $manager.create_object(Mobile, room, nil, :@generic => "tall man", :@short_desc => "A tall man with a very long beard stands here placidly.", :@alt_names => ["man"], :@show_in_look => "A tall man with a very long beard stands here regarding you placidly.", :@sex => "m")

  puts "Adding helper reactions..."

  FileUtils.mkdir "objects/reactions" if not File.exist? "objects/reactions/"

  File.open "objects/reactions/helper.rx", "w" do |f|
    f.write helper_reactions
  end

  man.load_reactions("helper")

  puts "Saving everything..."

  $manager.save_all
  $manager = nil

  puts "...done."
end

def delete_player

  print "Player to delete: "

  name = gets.strip

  puts "Attempting to delete #{name}...\n"

  manager = Manager.new

  if manager.player_exist? name

    manager.set_password name, "deleting"

    go = Gary.new

    puts "Attempting to load player..."

    player = manager.load_player(name, "deleting")

    puts "Attempting to delete player..."

    manager.delete_player name

    puts "Saving changes..."

    manager.save_all

    if manager.player_exist? name
      puts "Could not delete #{name}"
    else
      puts "Deleted #{name}"
    end
  else
    puts "#{name} does not exist."
  end
end

def change_password
  puts
  print "Player name: "
  name = gets.chomp

  manager = Manager.new(Gary.new)

  if manager.player_exist? name
    print "New password: "
    password = gets.chomp
    puts "Setting new password..."
    manager.set_password(name, password)
    puts "Verifying..."
    if manager.check_password(name, password)
      puts "Password set."
    else
      puts "Problem setting password."
    end
  else
    puts "Error: No player with that name."
  end
end

def change_goid
  current_setting = ServerConfig[:goid_type] || "GUID"
  puts "The Game Object ID is used to identify game objects."

  loop do
    puts "Currently, you are using #{current_setting} for GOIDs.\n"
    puts "1. GUID (Example: 51e4b36f-d6ae-1916-ebd6-0e23a6f9bcb1)",
      "2. 16-bit integer (numbers up to 65,536)",
      "3. 24-bit integer (numbers up to 16777216)",
      "4. 32-bit integer (numbers up to  4294967296)",
      "5. No change"

    choice = gets.strip.to_i

    case choice
    when 1
      ServerConfig[:goid_type] = :guid
      puts "Set GOID to use GUIDs"
      return
    when 2
      ServerConfig[:goid_type] = :integer_16
      puts "Set GOID to use integers up to 2^16"
      return
    when 3
      ServerConfig[:goid_type] = :integer_24
      puts "Set GOID to use integers up to 2^24"
      return
    when 4
      ServerConfig[:goid_type] = :integer_32
      puts "Set GOID to use integers up to 2^32"
      return
    when 5
      return
    end
  end
end

def config_options
  loop do
    keys = ServerConfig.options.sort_by {|a| a.to_s }

    puts "\nServer configuration options:"

    keys.each_with_index do |k, i|
      puts "#{i + 1}. #{k.to_s.gsub("_", " ").capitalize}"
    end

    puts "#{keys.length + 1}. Show current configuration"
    puts "#{keys.length + 2}. Return to main menu"

    print "? "
    answer = gets.chomp

    if answer =~ /^\d+$/
      answer = answer.to_i

      if answer == keys.length + 2
        return
      elsif answer == keys.length + 1
        show_config
      elsif answer <= keys.length and answer > 0
        set_config(keys[answer - 1])
      else
        puts "Invalid option"
      end
    else
      puts "Please choose one of the options."
    end
  end
end

def show_config
  puts "\nCurrent configuration:"

  keys = ServerConfig.options.sort_by {|a| a.to_s }

  keys.each_with_index do |k, i|
    puts "#{k.to_s.gsub("_", " ").capitalize}: #{ServerConfig[k]}"
  end

end

def set_config option

  puts "Option: #{option.to_s.gsub("_", " ").capitalize}", "Current value: #{ServerConfig[option]}"
  print "New value: "

  answer = gets.strip

  if answer.empty?
    puts "Keeping current configuration."
    return
  end

  case ServerConfig[option]
  when String
    ServerConfig[option] = answer
  when Integer, Float
    if answer.to_i == answer.to_f
      ServerConfig[option] = answer.to_i
    else
      ServerConfig[option] = answer.to_f
    end
  when Symbol
    ServerConfig[option] = answer.to_sym
  when TrueClass, FalseClass
    answer.downcase == "true" ? ServerConfig[option] = true : ServerConfig[option] = false
  else
    puts "What should this value be?"
    ["String", "Symbol", "Float", "Integer", "Boolean"].each_with_index do |o, i|
      puts "#{i + 1}. #{o}"
    end

    print "? "

    index = gets.strip

    case index
    when 1
      ServerConfig[option] = answer
    when 2
      ServerConfig[option] = answer.to_sym
    when 3
      ServerConfig[option] = answer.to_f
    when 4
      ServerConfig[option] = answer.to_i
    when 5
      answer.downcase == "true" ? ServerConfig[option] = true : ServerConfig[option] = false
    else
      puts "Not a valid option."
    end
  end

  puts "#{option.to_s.gsub("_", " ").capitalize} set to #{ServerConfig[option]}"
end

def helper_reactions
  <<'HERE'
!action
say hi emote
!test
event[:player].is_a? Player and not event[:player].admin
!reaction
"sayto #{event[:player].name} Oh, my. This is not a very interesting place for players who are not administrators."

!action
hi
!test
true
!reaction
player = event[:player]
"sayto #{player.name} Hello, #{player.name}. Is there some way I could help you today?"

!action
say
!test
event[:phrase] and event[:phrase].downcase.include? "help" and event[:player] != self
!reaction
player = event[:player]
"sayto #{player.name} I can help you with many things, such as: ADMIN, README, CONFIG, SETTINGS, LICENSE, CREATE, AREA, ROOM, EXAMINE, INFO, LIST, STATUS, WHO, PLAYERS."

!action
say
!test
event[:phrase] and event[:phrase].downcase.include? "config" and event[:player] != self
!reaction
player = event[:player]
"sayto #{player.name} You can configure your server using the ACONFIG command."

!action
say
!test
event[:phrase] and event[:phrase].downcase.include? "create" and event[:player] != self
!reaction
player = event[:player]
"sayto #{player.name} You can create new things using the ACREATE command, though it is better to use a specific creation command like ACPROP, ACEXIT, ACROOM, ACPORTAL, or ACAREA. Try out some of these commands if you are feeling creative."

!action
say
!test
event[:phrase] and event[:phrase].downcase.include? "area" and event[:player] != self
!reaction
player = event[:player]
"sayto #{player.name} You can see where you are and what area you are in with LOOK HERE. See all areas with the AREAS command."

!action
say
!test
event[:phrase] and event[:phrase].downcase.include? "room" and event[:player] != self
!reaction
player = event[:player]
"sayto #{player.name} The room you are standing in can always be referring to as 'here'. For example, LOOK HERE or APUT ME IN HERE."

!action
say
!test
event[:phrase] and event[:phrase].downcase.include? "examine" and event[:player] != self
!reaction
player = event[:player]
"sayto #{player.name} There are several ways to examine items. The most informative method is to use ALOOK. ALOOK by itself will show you information about your current room. Or you can use it with a target, like ALOOK MAN. You can set attributes with the ASET command. Also ask me about INFO and REACTIONS."

!action
say
!test
event[:phrase] and event[:phrase].downcase.include? "info" and event[:player] != self
!reaction
player = event[:player]
"sayto #{player.name} Every game object has an Info object which can hold arbitrary information about an object. This is much easier and flexible than using attributes or instance variables. You can manipulate an object's information with the AINFO command."

!action
say
!test
event[:phrase] and event[:phrase].downcase.include? "list" and event[:player] != self
!reaction
player = event[:player]
"sayto #{player.name} ALIST is a very useful command. By itself, it will list all objects in the game. But you can also use it to search for specific items."

!action
say
!test
event[:phrase] and event[:phrase].downcase.include? "status" and event[:player] != self
!reaction
player = event[:player]
"sayto #{player.name} Check out how many objects are in the game with the ASTATUS command."

!action
say
!test
event[:phrase] and event[:phrase].downcase.include? "who" and event[:player] != self
!reaction
player = event[:player]
"sayto #{player.name} What are you, an owl? WHO will list all the players currently in the game and their locations."

!action
say
!test
event[:phrase] and event[:phrase].downcase.include? "players" and event[:player] != self
!reaction
player = event[:player]
"sayto #{player.name} If you build it, they will come."

!action
say
!test
event[:phrase] and event[:phrase].downcase.include? "reaction" and event[:player] != self
!reaction
player = event[:player]
"sayto #{player.name} Reactions are how I am communicating with you. They can be specified in text files (preferably) or code. To manipulate an object's reactions, use the AREACT command."

!action
say
!test
event[:phrase] and event[:phrase].downcase.include? "admin" and event[:player] != self
!reaction
player = event[:player]
"sayto #{player.name} you can view help files on the administrator commands using AHELP."

!action
say
!test
event[:phrase] and event[:phrase].downcase.include? "readme" and event[:player] != self
!reaction
player = event[:player]
player.output File.read("README")
""

!action
say
!test
event[:phrase] and event[:phrase].downcase.include? "license" and event[:player] != self
!reaction
player = event[:player]
r1 = CommandParser.parse(self, "say Wait. What game?")
r2 = CommandParser.parse(self, "emote looks about wildly, a look of raw horror passing over his face.")
r3 = CommandParser.parse(self, "emote calms down and returns to his usual helpful self.")
e1 = CommandParser.future_event(self, 2, r1)
e2 = CommandParser.future_event(self, 3, r2)
e3 = CommandParser.future_event(self, 6, r3)

add_event e1
add_event e2
add_event e3

"sayto #{player.name} This game is released under GPLv2 except where noted in the source."

!action
say
!test
event[:phrase] and event[:phrase].downcase.include? "setting" and event[:player] != self
!reaction
player = event[:player]
"sayto #{player.name} You can set different things for yourself using SET. See HELP SET for more."
HERE
end

setup_menu if __FILE__ == $0

