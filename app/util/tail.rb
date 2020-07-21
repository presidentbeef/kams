class File
  # = File::Tail - Tailing files in Ruby
  #
  # == Description
  #
  # This is a small ruby library that allows it to "tail" files in Ruby,
  # including following a file, that still is growing like the unix command 'tail
  # -f' can.
  #
  # == Author
  #
  # Florian Frank mailto:flori@ping.de
  #
  # == License
  #
  # This is free software; you can redistribute it and/or modify it under
  # the terms of the GNU General Public License Version 2 as published by
  # the Free Software Foundation: http://www.gnu.org/copyleft/gpl.html
  #
  # == Download
  #
  # The latest version of <b>File::Tail</b> (file-tail) can be found at
  #
  # http://rubyforge.org/frs/?group_id=393
  #
  # Online Documentation should be located at
  #
  # http://file-tail.rubyforge.org
  #
  # == Usage
  #
  # File::Tail is a module in the File class. A lightweight class interface for
  # logfiles can be seen under File::Tail::Logfile.
  #
  # Direct extension of File objects with File::Tail works like that:
  #  File.open(filename) do |log|
  #    log.extend(File::Tail)
  #    log.interval = 10
  #    log.backward(10)
  #    log.tail { |line| puts line }
  #  end
  #
  # It's also possible to mix File::Tail in your own File classes
  # (see also File::Tail::Logfile):
  #  class MyFile < File
  #    include File::Tail
  #  end
  #  log = MyFile.new("myfile")
  #  log.interval = 10
  #  log.backward(10)
  #  log.tail { |line| print line }
  #
  # The forward/backward method returns self, so it's possible to chain
  # methods together like that:
  #  log.backward(10).tail { |line| puts line }
  #
  module Tail
    # This is an easy to use Logfile class that includes
    # the File::Tail module.
    #
    # === Usage
    # The unix command "tail -10f filename" can be emulated like that:
    #  File::Tail::Logfile.open(filename, :backward => 10) do |log|
    #    log.tail { |line| puts line }
    #  end
    #
    # Or a bit shorter:
    #  File::Tail::Logfile.tail(filename, :backward => 10) do |line|
    #    puts line
    #  end
    #
    # To skip the first 10 lines of the file do that:
    #  File::Tail::Logfile.open(filename, :forward => 10) do |log|
    #    log.tail { |line| puts line }
    #  end
    #
    # The unix command "head -10 filename" can be emulated like that:
    #  File::Tail::Logfile.open(filename, :return_if_eof => true) do |log|
    #    log.tail(10) { |line| puts line }
    #  end
    class Logfile < File
      include File::Tail

      # This method creates an File::Tail::Logfile object and
      # yields to it, and closes it, if a block is given, otherwise it just
      # returns it. The opts hash takes an option like
      # * <code>:backward => 10</code> to go backwards
      # * <code>:forward => 10</code> to go forwards
      # in the logfile for 10 lines at the start. The buffersize
      # for going backwards can be set with the
      # * <code>:bufsiz => 8192</code> option.
      # To define a callback, that will be called after a reopening occurs, use:
      # * <code>:after_reopen => lambda { |file| p file }</code>
      #
      # Every attribute of File::Tail can be set with a <code>:attributename =>
      # value</code> option.
      def self.open(filename, opts = {}, &block) # :yields: file
        file = new filename
        opts.each do |o, v|
          writer = o.to_s + "="
          file.__send__(writer, v) if file.respond_to? writer
        end
        if opts.key?(:wind) or opts.key?(:rewind)
          warn ":wind and :rewind options are deprecated, "\
            "use :forward and :backward instead!"
        end
        if backward = opts[:backward] || opts[:rewind]
          (args = []) << backward
          args << opt[:bufsiz] if opts[:bufsiz]
          file.backward(*args)
        elsif forward = opts[:forward] || opts[:wind]
          file.forward(forward)
        end
        if opts[:after_reopen]
          file.after_reopen(&opts[:after_reopen])
        end
        if block_given?
          begin
            block.call file
          ensure
            file.close
            nil
          end
        else
          file
        end
      end

      # Like open, but yields to every new line encountered in the logfile in
      # +block+.
      def self.tail(filename, opts = {}, &block)
        if ([ :forward, :backward ] & opts.keys).empty?
          opts[:backward] = 0
        end
        open(filename, opts) do |log|
          log.tail { |line| block.call line }
        end
      end
    end

    # This is the base class of all exceptions that are raised
    # in File::Tail.
    class TailException < Exception; end

    # The DeletedException is raised if a file is
    # deleted while tailing it.
    class DeletedException < TailException; end

    # The ReturnException is raised and caught
    # internally to implement "tail -10" behaviour.
    class ReturnException < TailException; end

    # The BreakException is raised if the <code>break_if_eof</code>
    # attribute is set to a true value and the end of tailed file
    # is reached.
    class BreakException < TailException; end

    # The ReopenException is raised internally if File::Tail
    # gets suspicious something unusual has happend to
    # the tailed file, e. g., it was rotated away. The exception
    # is caught and an attempt to reopen it is made.
    class ReopenException < TailException
      attr_reader :mode

      # Creates an ReopenException object. The mode defaults to
      # <code>:bottom</code> which indicates that the file
      # should be tailed beginning from the end. <code>:top</code>
      # indicates, that it should be tailed from the beginning from the
      # start.
      def initialize(mode = :bottom)
        super(self.class.name)
        @mode = mode
      end
    end

    # The maximum interval File::Tail sleeps, before it tries
    # to take some action like reading the next few lines
    # or reopening the file.
    attr_accessor :max_interval

    # The start value of the sleep interval. This value
    # goes against <code>max_interval</code> if the tailed
    # file is silent for a sufficient time.
    attr_accessor :interval

    # If this attribute is set to a true value, File::Tail persists
    # on reopening a deleted file waiting <code>max_interval</code> seconds
    # between the attempts. This is useful if logfiles are
    # moved away while rotation occurs but are recreated at
    # the same place after a while. It defaults to true.
    attr_accessor :reopen_deleted

    # If this attribute is set to a true value, File::Tail
    # attempts to reopen it's tailed file after
    # <code>suspicious_interval</code> seconds of silence.
    attr_accessor :reopen_suspicious

    # The callback is called with _self_ as an argument after a reopen has
    # occured. This allows a tailing script to find out, if a logfile has been
    # rotated.
    def after_reopen(&block)
      @after_reopen = block
    end

    # This attribute is the invterval in seconds before File::Tail
    # gets suspicious that something has happend to it's tailed file
    # and an attempt to reopen it is made.
    #
    # If the attribute <code>reopen_suspicious</code> is
    # set to a non true value, suspicious_interval is
    # meaningless. It defaults to 60 seconds.
    attr_accessor :suspicious_interval

    # If this attribute is set to a true value, File::Fail's tail method
    # raises a BreakException if the end of the file is reached.
    attr_accessor :break_if_eof

    # If this attribute is set to a true value, File::Fail's tail method
    # just returns if the end of the file is reached.
    attr_accessor :return_if_eof

    # Skip the first <code>n</code> lines of this file. The default is to don't
    # skip any lines at all and start at the beginning of this file.
    def forward(n = 0)
      seek(0, File::SEEK_SET)
      while n > 0 and not eof?
        readline
        n -= 1
      end
      self
    end

    # Rewind the last <code>n</code> lines of this file, starting
    # from the end. The default is to start tailing directly from the
    # end of the file.
    #
    # The additional argument <code>bufsiz</code> is
    # used to determine the buffer size that is used to step through
    # the file backwards. It defaults to the block size of the
    # filesystem this file belongs to or 8192 bytes if this cannot
    # be determined.
    def backward(n = 0, bufsiz = nil)
      if n <= 0
        seek(0, File::SEEK_END)
        return self
      end
      bufsiz ||= stat.blksize || 8192
      size = stat.size
      begin
        if bufsiz < size
          seek(0, File::SEEK_END)
          while n > 0 and tell > 0 do
            start = tell
            seek(-bufsiz, File::SEEK_CUR)
            buffer = read(bufsiz)
            n -= buffer.count("\n")
            seek(-bufsiz, File::SEEK_CUR)
          end
        else
          seek(0, File::SEEK_SET)
          buffer = read(size)
          n -= buffer.count("\n")
          seek(0, File::SEEK_SET)
        end
      rescue Errno::EINVAL
        size = tell
        retry
      end
      pos = -1
      while n < 0  # forward if we are too far back
        pos = buffer.index("\n", pos + 1)
        n += 1
      end
      seek(pos + 1, File::SEEK_CUR)
      self
    end

    # This method tails this file and yields to the given block for
    # every new line that is read.
    # If no block is given an array of those lines is
    # returned instead. (In this case it's better to use a
    # reasonable value for <code>n</code> or set the
    # <code>return_if_eof</code> or <code>break_if_eof</code>
    # attribute to a true value to stop the method call from blocking.)
    #
    # If the argument <code>n</code> is given, only the next <code>n</code>
    # lines are read and the method call returns. Otherwise this method
    # call doesn't return, but yields to block for every new line read from
    # this file for ever.
    def tail(n = nil, &block) # :yields: line
      @n = n
      result = []
      array_result = false
      unless block
        block = lambda { |line| result << line }
        array_result = true
      end
      preset_attributes unless @lines
      loop do
        begin
          restat
          read_line(&block)
          redo
        rescue ReopenException => e
          until eof? || @n == 0
            block.call readline
            @n -= 1 if @n
          end
          reopen_file(e.mode)
          @after_reopen.call self if @after_reopen
        rescue ReturnException
          return array_result ? result : nil
        end
      end
    end

    private

    def read_line(&block)
      if @n
        until @n == 0
          block.call readline
          @lines += 1
          @no_read = 0
          @n -= 1
          debug
        end
        raise ReturnException
      else
        block.call readline
        @lines += 1
        @no_read = 0
        debug
      end
    rescue EOFError
      seek(0, File::SEEK_CUR)
      raise ReopenException if @reopen_suspicious and
        @no_read > @suspicious_interval
      raise BreakException if @break_if_eof
      raise ReturnException if @return_if_eof
      sleep_interval
    rescue Errno::ENOENT, Errno::ESTALE
      raise ReopenException
    end

    def preset_attributes
      @reopen_deleted       = true if @reopen_deleted.nil?
      @reopen_suspicious    = true if @reopen_suspicious.nil?
      @break_if_eof         = false if @break_if_eof.nil?
      @return_if_eof        = false if @return_if_eof.nil?
      @max_interval         ||= 10
      @interval             ||= @max_interval
      @suspicious_interval  ||= 60
      @lines                = 0
      @no_read              = 0
    end

    def restat
      stat = File.stat(path)
      if @stat
        if stat.ino != @stat.ino or stat.dev != @stat.dev
          @stat = nil
          raise ReopenException.new(:top)
        end
        if stat.size < @stat.size
          @stat = nil
          raise ReopenException.new(:top)
        end
      else
        @stat = stat
      end
    rescue Errno::ENOENT, Errno::ESTALE
      raise ReopenException
    end

    def sleep_interval
      if @lines > 0
        # estimate how much time we will spend on waiting for next line
        @interval = (@interval.to_f / @lines)
        @lines = 0
      else
        # exponential backoff if logfile is quiet
        @interval *= 2
      end
      if @interval > @max_interval
        # max. wait @max_interval
        @interval = @max_interval
      end
      debug
      sleep @interval
      @no_read += @interval
    end

    def reopen_file(mode)
      $DEBUG and $stdout.print "Reopening '#{path}', mode = #{mode}.\n"
      @no_read = 0
      reopen(path)
      if mode == :bottom
        backward
      end
    rescue Errno::ESTALE, Errno::ENOENT
      if @reopen_deleted
        sleep @max_interval
        retry
      else
        raise DeletedException
      end
    end

    def debug
=begin
      $DEBUG or return
      STDERR.puts({
        :lines    => @lines,
        :interval => @interval,
        :no_read  => @no_read,
        :n        => @n,
      }.inspect)
=end
    end
  end
end

if $0 == __FILE__
  filename = ARGV.shift or fail "Usage: #$0 filename [number]"
  number = (ARGV.shift || 0).to_i
  File.open(filename) do |log|
    log.extend(File::Tail)
    # Some settings to make watching tail.rb with "ruby -d" fun
    log.interval            = 1
    log.max_interval        = 5
    log.reopen_deleted      = true # is default
    log.reopen_suspicious   = true # is default
    log.suspicious_interval = 20
    number >= 0 ? log.backward(number, 8192) : log.forward(-number)
    #loop do          # grab 5 lines at a time and return
    #  log.tail(5) { |line| puts line }
    #  print "Got 5!\n"
    #end
    log.tail { |line| puts line }
  end
end
# vim: set et sw=2 ts=2:
