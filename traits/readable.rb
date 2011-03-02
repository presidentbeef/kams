#Makes it possible to 'read' an object (like a book or scroll).
#
#Currently this only supports a single 'page' of text. It will need to be expanded later to have items like books
#with multiple pages of text.
module Readable

  attr_accessor :readable_text

  def initialize(*args)
    super

    @readable_text = nil
    @actions << "read"
  end

  def read(event, player, room)
    if player.blind?
      player.output "You cannot read when you are blind."
      return false
    elsif @readable_text.nil?
      player.output "Nothing is written there."
    else
      player.output("You read:", true)
      player.output "\"#{@readable_text}\""
    end
  end
end
