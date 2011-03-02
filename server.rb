#!/usr/bin/env ruby
=begin
Homepage:       http://kingdomsofahln.com/
Author:         Justin Collins
Copyright:      2008, Justin Collins
License:        GPL unless otherwise noted.

    This file is part of the Kingdoms of Ahln MUD Server (KAMS).

    KAMS is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or
    (at your option) any later version.

    KAMS is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with KAMS.  If not, see <http://www.gnu.org/licenses/>.
=end
$KAMS_VERSION = "0.2.3"
$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require 'rubygems'
require 'eventmachine'
require 'util/config'
require 'util/log'
require 'lib/util'
require 'components/manager'
require 'lib/playerconnect'

#The Server is what starts everything up. In fact, that is pretty much all it does. To use, call Server.new.
class Server
  #This is the main server loop. Just call it.
  #Creates the Manager, starts the EventMachine, and closes everything down when the time comes.
  def initialize(address, port)
    $manager = Manager.new
    EventMachine.run do
      EventMachine.add_periodic_timer(ServerConfig.update_rate) { $manager.update_all }
      if ServerConfig.save_rate and ServerConfig.save_rate > 0
        EventMachine.add_periodic_timer(ServerConfig.save_rate * 60) { log "Automatic state save."; $manager.save_all }
      end
      EventMachine.start_server address, port, PlayerConnection
      File.open("logs/server.log", "a") { |f| f.puts "#{Time.now} Server started." }
      log "Server up and running on #{address}:#{port}", 0
    end
  rescue Interrupt => i
    log "Received interrupt: halting", 0
    log i.inspect
    log i.backtrace.join("\n"), 0, true
  rescue Exception => e
    log e.backtrace.join("\n"), 0, true
    log e.inspect
  ensure
    $manager.stop
    log "Saving objects...", Logger::Normal, true
    $manager.save_all
    log "Objects saved.", Logger::Normal, true
  end
end

#Start the server.
if __FILE__ == $0

  if ARGV[0]
    server_restarts = ARGV[0].to_i
  else
    server_restarts = 0
  end

  log "Server restart ##{server_restarts}"

  begin
    #result = RubyProf.profile do
    Server.new(ServerConfig.address, ServerConfig.port)
    #end
    #File.open "logs/profile", "w" do |f|
    # RubyProf::CallTreePrinter.new(result).print f, 1
    #end
  ensure
    if server_restarts < ServerConfig.restart_limit
      if $manager and $manager.soft_restart
        log "Server restart initiated by administrator."
        File.open("logs/server.log", "a+") { |f| f.puts "#{Time.now} Server restart by administrator." }
      else
        File.open("logs/server.log", "a+") { |f| f.puts "#{Time.now} Server restart on error or interrupt." }
      end

      log "SERVER RESTARTING - Attempting to restart in 10 seconds...press ^C to stop...", Logger::Important
      sleep ServerConfig.restart_delay
      log "RESTARTING SERVER", Logger::Important, true

      program_name = ENV["_"] || "ruby"

      if $manager and $manager.soft_restart
        exec("#{program_name} server.rb")
      else
        exec("#{program_name} server.rb #{server_restarts + 1}")
      end
    else
      File.open("logs/server.log", "a") { |f| f.puts "#{Time.now} Server stopping. Too many restarts." }
      log "Too many restarts, giving up.", Logger::Important, true
    end
  end
end
