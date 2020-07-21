#Simplistic logging with buffer and autodeletion of the log when it gets too big.
class Logger
  Ultimate = 3
  Medium = 2
  Normal = 1
  Important = 0

  def initialize(log_file = "logs/system.log", buffer_size = 45, buffer_time = 300, max_log_size = 50000000)
    ServerConfig[:log_level] ||= 1
    @last_dump = Time.now
    @entries = []
    @log_file = log_file
    @buffer_size = buffer_size
    @buffer_time = buffer_time
    @max_log_size = max_log_size
  end

  #Log something.
  def add(msg, log_level = Normal, dump_log = false)

    if log_level <= ServerConfig[:log_level]
      $stderr.puts msg

      @entries << msg

      if dump_log || @entries.length > @buffer_size || (Time.now - @last_dump > @buffer_time)
        self.dump
      end
    end
  end

  #Write buffered logs to disk, check if log file is too large.
  def dump
    unless @entries.empty?
      if File.exist?(@log_file) and File.size(@log_file) > @max_log_size
        @entries << "!!!DELETED LOG FILE - SIZE: #{File.size(@log_file)}"
        File.delete(@log_file)
      end

      File.open(@log_file, "a") do |f|
        f.puts @entries
      end
    end
    self.clear
  end

  #Empty buffer (assumes already wrote to disk).
  def clear
    num_entries = @entries.length
    @entries.clear
    @last_dump = Time.now
    GC.start
  end

  alias :<< :add
end

unless Object.respond_to? :log, true

  class Object

    #Log a message and optionally force writing to disk.
    def log(msg, log_level = Logger::Normal, dump_log = false)
      logmsg = "[#{Time.now.strftime("%x %X")} #{self.class}#{(defined? GameObject and self.is_a? GameObject) ? " #{self.name}" : ""}]: " + msg.to_s
      $LOG ||= Logger.new
      $LOG.add(logmsg, log_level, dump_log)
    end

    private :log
  end
end
