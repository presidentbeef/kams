#In-game editor. This module is included in PlayerConnection and is not used separately.
module Editor

  #Start up the editor. The results from the editor will be yielded to the given block.
  #
  #The Player is removed from any room, putting them in a limbo state.
  def start_editor(buffer = [], limit = 100, &callback)
    if buffer.is_a? Array
      @editor_buffer = buffer
    else
      @editor_buffer = buffer.split("\n")
    end
    if @editor_buffer.empty?
      @editor_line = 0
    else
      @editor_line = @editor_buffer.length
    end

    @limit = limit

    #Take player out of the game
    container = $manager.find @player.container
    container.inventory.remove(@player)
    @player.container = nil
    container.output "#{@player.name} wanders off with a quill pen in #{@player.pronoun(:possessive)} hand, lost in thought."
    @player.info.former_room = container.goid

    @editing = true
    @editor_callback = callback

    editor_out "Type *help for help."
    editor_out("-" * (@word_wrap || 80))
    editor_echo
  end

  #Show the editor prompt.
  def editor_prompt
    self.print "<editor>#{@editor_line + 1}]</> #{IAC + GA}"
  end

  #Handle input.
  def editor_input input
    case input.downcase
    when '*quit', '*cancel', '*q', '*exit'
      editor_quit
    when '*save', '*s'
      editor_save
    when '*clear', '*c'
      editor_clear
    when '*echo', '*show', '*e'
      editor_echo
    when '*more', '*m'
      more
      editor_prompt
    when '*help', '*h'
      editor_help(nil)
    else
      case input
      when /^\*(l|line|g|go)\s+(.*)/i
        editor_go $2.to_i
      when /^\*(dl|delete)\s+(.*)/i
        editor_delete $2.to_i
      when /^\*(r|replace)\s+(\d)\s+(.*)/i
        editor_replace($2.to_i, $3)
      when /^\*(h|help)\s+(.*)/
        editor_help($2)
      when /^\*/
        editor_out "Unknown command. Please see use *help to view help."
        editor_prompt
      else
        editor_append input
      end
    end
  end

  #Append input to buffer.
  def editor_append input
    if @editor_line >= @limit
      self.puts "You have run out of room on this document."
    else
      @editor_buffer.insert(@editor_line, input)
      @editor_line += 1
    end

    if @editor_line >= @limit
      self.puts "You have run out of room on this document."
    end
    editor_prompt
  end

  #Handle help command.
  def editor_help command = nil
    case command
    when "save", "*save"
      editor_out "*save will save your writing and exit the editor."
    when "quit", "*quit"
      editor_out "*quit will prompt you to save or exit without saving."
    when "echo", "*echo"
      editor_out "*echo will show you what has been written so far."
    when "delete", "*delete"
      editor_out "*delete <line number> will delete that line."
    when "line", "*line"
      editor_out "*line <line number> will move to that line."
    when "replace", "*replace"
      editor_out "*replace <line number> <input> will replace a line with that input."
    when "more", "*more"
      editor_out "*more works like MORE regularly does."
    else
      editor_out "The following commands are available: *save, *quit, *echo, *delete, *line, *more and *replace.\nType *help <command> for more information."
    end

    editor_prompt
  end

  #Output a message while in the editor.
  #
  #Basically just colors the output.
  def editor_out message
    self.puts "<editor>#{message}</editor>"
  end

  #Replace a line in the buffer.
  def editor_replace(line, data)
    if line > @editor_buffer.length
      editor_out "Cannot go past end of document."
    elsif line < 1
      editor_out "Cannot go past start of document."
    else
      @editor_buffer[line - 1] = data
      editor_out "Replaced line #{line}."
    end

    editor_prompt
  end

  #Delete a line in the buffer.
  def editor_delete line
    if line > @editor_buffer.length
      editor_out "Cannot go past end of document."
    elsif line < 1
      editor_out "Cannot go past start of document."
    else
      @editor_buffer.delete_at(line - 1)
      @editor_line -= 1 unless @editor_line == 0
      editor_out "Deleted line #{line}."
    end

    editor_prompt
  end

  #Go to a line in the buffer.
  def editor_go line
    if line > @editor_buffer.length + 1
      editor_out "Cannot go past end of document."
    elsif line < 1
      editor_out "Cannot go past start of document."
    else
      @editor_line = line - 1
      editor_out "Moved to before line #{line}."
    end

    editor_prompt
  end

  #Echo the current buffer.
  def editor_echo
    line = 0
    self.print(@editor_buffer.map {|l| line += 1; "<editor>#{line}]</> #{l}"}.join("\n"), true, true)
    editor_prompt
  end

  #Leave the editor. Asks if the Player wishes to save.
  def editor_quit
    editor_out "Do you wish to save (Yes/No/Cancel)?"
    expect do |input|
      input.downcase!
      case input
      when /^y/
        editor_save
      when /^n/
        editor_really_quit
      else
        editor_out "Resuming editing at line #{@editor_line + 1}."
        editor_prompt
      end
    end
  end

  #Save buffer and call fix_player.
  def editor_save
    @editing = false
    @editor_callback[@editor_buffer.join("\n")]
    @editor_buffer = nil
    @editor_callback = nil
    fix_player
  end

  #Quit without saving.
  def editor_really_quit
    @editing = false
    @editor_callback[nil]
    @editor_callback = nil
    @editor_buffer = nil
    fix_player
  end

  #Clear the buffer.
  def editor_clear
    @editor_buffer.clear
    @editor_line = 0
    editor_out "Cleared document."
    editor_prompt
  end

  #Put the Player back in the proper Room.
  def fix_player
    room = $manager.find(@player.info.former_room)
    room.add @player
    room.output("#{@player.name} walks back in, finished with #{@player.pronoun(:possessive)} writing.", @player)
  end
end
