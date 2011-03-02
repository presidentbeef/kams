require 'gdbm'

#Contains the functionality for newsboards.
#
#Each board has its own gdbm database in storage/boards/ which is stored as a hash of post ids to posts. Posts are just hashes which look like:
#
# { :title =>
#   :author =>
#   :reply_to =>
#   :message =>
#   :timestamp =>
#   :post_id =>
# }
module News

  #Save post information to a new post
  def save_post(player, title, reply_to, message)
    posts = nil
    open_store(goid) do |gd|
      posts = gd.length
    end
    posts += 1
    post_info = { :title => title, :author => player.name, :reply_to => reply_to, :message => message, :timestamp => Time.now.to_i, :post_id => posts}
    log "Dumping #{post_info.inspect}"
    post = Marshal.dump(post_info)
    open_store(goid, false) do |gd|
      gd[posts.to_s] = post
    end
    posts
  end

  #Gets the post.
  def get_post id
    id = id.to_s
    open_store(goid) do |gd|
      if gd.has_key? id
        Marshal.load(gd[id])
      else
        log "No such post (#{id}) in #{goid}"
        nil
      end
    end
  end

  #Pass a post (hash) or post id to show to the player
  def show_post(post, word_wrap = 80)
    unless post.is_a? Hash
      get_post post
    end

    output = []
    output << ("<news>" << info.board_name + " ##{post[:post_id]}" << "</>")
    output << "Subj: #{post[:title]}"
    unless post[:reply_to].nil?
      parent = get_post post[:reply_to]
      if parent
        output << "Re  : '#{parent[:title]}' by #{parent[:author]} (#{post[:reply_to]})"
      end
    end
    output << "By  : #{post[:author]}"
    output << "Date: #{$manager.date_at(post[:timestamp])} (#{Time.at(post[:timestamp]).utc})"
    output << ("-" * word_wrap)

    output << post[:message]

    output << ("-" * word_wrap)

    replies = list_replies(post[:post_id], word_wrap)
    if replies
      output + replies
    else
      output
    end
  end

  #List the latest posts.
  #
  #Offset will skip that many posts. Not all that useful at the moment.
  def list_latest(wordwrap = 100, offset = 0, limit = 20)
    latest = {}
    wordwrap ||= 100
    open_store(goid) do |gd|
      if limit.nil?
        limit = gd.length
      else
        limit = limit.to_i
      end

      latest_keys = gd.keys.collect { |k| k.to_i}.sort.reverse[offset, limit]
      if latest_keys.nil?
        break
      else
        latest_keys.collect {|k| k.to_s }.each do |k|
          latest[k.to_i] = Marshal.load(gd[k])
        end
      end
    end

    output = ["<news>" << @info.board_name + "</>"]
    if latest.empty?
      output << "No posts to show."
    else
      length_limit = wordwrap - 25
      indents = {}
      indent = 0
      tree = tree_list latest

      tree.each_with_index do |id, index|
        post = latest[id]
        reply = post[:reply_to].to_i
        if reply and latest.include? reply
          if tree[index - 1] == reply
            indent += 2
          else
            indent = indents[reply] + 2
          end
        else
          indent = 0
        end

        indents[id] = indent

        if indent == 0
          output << "-"
        end
        output << ((" " * indent) + post_summary(post, length_limit + index))
      end

      posts = nil
      open_store goid do |gd|
        posts = gd.length
      end

      last_post = tree.max
      if last_post < posts and tree.min != 1
        output << "--NEWS #{last_post} for more--"
      end
    end

    output
  end

  #Returns an array of post summaries that are replies to the give post id.
  def list_replies id, wordwrap
    wordwrap ||= 80
    id = id.to_s
    replies = {}
    open_store goid do |gd|
      gd.each_value do |dpost|
        post = Marshal.load(dpost)
        if post[:reply_to].to_s == id
          replies[post[:post_id].to_i] = post
        end
      end
    end

    if replies.empty?
      nil
    else
      output = ["Replies:"]
      replies.keys.sort.each do |post_id|
        output << " " + post_summary(replies[post_id], wordwrap)
      end
      output
    end
  end

  #Deletes the post.
  def delete_post id
    open_store(goid, false) do |gd|
      gd.delete id
    end
  end

  #Returns announcement (String) for new posts.
  def announce_new
    info.announce_new
  end

  private

  #Returns an array of post ids in a sort of tree ordering. Kind of weird.
  def tree_list latest
    tree = []

    latest.keys.sort.reverse_each do |id|
      post = latest[id]
      reply = post[:reply_to].to_i

      if tree.include? id
        next
      elsif reply and latest.include? reply
        until tree.include? reply
          insert_parent tree, latest, id
        end
        tree.insert(tree.index(reply) + 1, id)
      else
        tree << id
      end
    end
    tree
  end

  #Finds and adds the highest parent for a post.
  def insert_parent tree, latest, id
    reply = latest[id][:reply_to].to_i
    if reply.nil?
      tree << id
    elsif not latest.include? reply
      tree << id
    elsif tree.include? reply
      tree.insert(tree.index(reply) + 1, id)
    else
      insert_parent tree, latest, reply
    end
  end

  #Returns a String for the summary of the given post. length_limit will crop the title if necessary.
  def post_summary(post, length_limit)
    "#{post[:post_id]}. <news>#{post[:author]}</>: #{post[:title][0, length_limit]}"
  end

  #Opens up the store with the given file name and yields it to the given block.
  def open_store(file, read_only = true)
    file = file.to_s
    #@mutex.synchronize do
      GDBM.open("storage/boards/" + file) do |gd|
        yield gd
      end
    #end
  end
end
