module News
  class << self

    #Show latest news on a Newsboard.
    def latest_news(event, player, room)
      board = find_board(event, room)

      if board.nil?
        player.output "There do not seem to be any postings here."
        return
      end

      if not board.is_a? Newsboard
        log board.class
      end

      offset = event[:offset] || 0
      wordwrap = player.word_wrap || 100
      limit = event[:limit] || player.page_height

      player.output board.list_latest(wordwrap, offset, limit)
    end

    #Show all news on a Newsboard.
    def all(event, player, room)
      board = find_board(event, room)

      if board.nil?
        player.output "There do not seem to be any postings here."
        return
      end

      wordwrap = player.word_wrap || 100

      player.output board.list_latest(wordwrap, 0, nil)
    end

    #Read a specific post.
    def read_post(event, player, room)
      board = find_board(event, room)

      if board.nil?
        player.output "There do not seem to be any postings here."
        return
      end

      post = board.get_post event[:post_id]
      if post.nil?
        player.output "No such posting here."
        return
      end

      if player.info.boards.nil?
        player.info.boards = {}
      end

      player.info.boards[board.goid] = event[:post_id].to_i

      player.output board.show_post(post, player.word_wrap || 80)
    end

    #Write a post.
    def write_post(event, player, room)
      board = find_board(event, room)

      if board.nil?
        player.output "There do not seem to be any postings here."
        return
      end

      player.output("What is the subject of this post?", true)

      player.expect do |subj|
        player.editor do |message|
          unless message.nil?
            post_id = board.save_post(player, subj, event[:reply_to], message)
            player.output "You have written post ##{post_id}."
            if board.announce_new
              area = $manager.get_object(board.container).area
              area.output board.announce_new
            end
          end
        end
      end
    end

    #Delete a post.
    #
    #Note: this is not handled very well, as it is not expected
    #to be a common occurance. In the future, this will be an admin-only command.
    def delete_post(event, player, room)
      #if not player.admin
      # player.output "You cannot do that."
      #end

      board = find_board(event, room)

      if board.nil?
        player.output "What newsboard are you talking about?"
        return
      end

      post = board.get_post event[:post_id]

      if post.nil?
        player.output "No such post."
      elsif post[:author] != player.name
        player.output "You can only delete your own posts."
      else
        board.delete_post event[:post_id]
        player.output "Deleted post ##{event[:post_id]}"
      end
    end

    #List from last read item onwards.
    #
    #Not quite working yet.
    def list_unread(event, player, room)
      board = find_board(event, room)

      if board.nil?
        player.output "There do not seem to be any postings here."
        return
      end

      if player.info.boards.nil?
        player.info.boards = {}
      end

      player.output board.list_since(player.info.boards[board.goid], player.word_wrap)
    end

    #Show posts after a given post.
    def list_before(event, player, room)
      board = find_board(event, room)

      if board.nil?
        player.output "There do not seem to be any postings here."
        return
      end

      player.output board.list_latest(player.word_wrap, event[:start_index].to_i - 1)
    end

    private

    #Find the Newsboard in the room.
    def find_board(event, room)
      boards = room.inventory.find_all("class", :Newsboard)
      boards.first unless boards.nil?
    end

  end
end
