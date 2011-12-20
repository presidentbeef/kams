require 'util/paginator'

#Wraps up the Paginator class to make it easier to use in the game.
class KPaginator

  #Pass in page length and the message as an Array of lines.
  def initialize(player, message)
    @message = message
    @my_p = Paginator.new(@message.size, player.page_height) do |offset, per_page|
      @message[offset, per_page]
    end
    @current = 0
    @pages = @my_p.number_of_pages
  end

  #Displays next page of text.
  def more
    @current += 1
    return "There is no more.\r\n" if @current > @pages
    page = @my_p.page(@current)
    if more?
      page.items.join("\r\n") << "\r\n---Type MORE for next page (#{@current}/#{@pages})---\r\n"
    else
      page.items.join("\r\n") << "\r\n"
    end
  end

  #True if there is another page of text.
  def more?
    @current < @pages
  end

  #Returns current page number.
  def current
    @current
  end

  #Returns size of the message.
  def lines
    @message.size
  end

  #Returns number of pages.
  def pages
    @pages
  end

end
