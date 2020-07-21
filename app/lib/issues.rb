#Generic module for storing and manipulating issues
#like ideas, bugs, and typos
module Issues
  class << self
    def add_issue type, reporter, report
      issue = nil
      open_store type, false do |gd|
        issue = { :type => type, :reporter => reporter.capitalize, :date => Date.today, :report => [report], :id => next_id(gd), :status => "new" }
        gd[issue[:id]] = Marshal.dump issue
      end
      issue
    end

    def get_issue type, id
      id = id.to_s
      open_store type do |gd|
        if gd.has_key? id
          Marshal.load gd[id]
        else
          nil
        end
      end
    end

    def check_access type, id, player
      issue = get_issue type, id
      if issue.nil?
        "There is no #{type} with that number."
      elsif not player.admin and issue[:reporter].downcase != player.name.downcase
        "You cannot access that #{type}."
      else
        nil
      end
    end

    def show_issue type, id
      issue = get_issue type, id
      if issue.nil?
        "No such #{type} with ID of #{id.inspect}."
      else
      <<-END
------------------
#{type.to_s.capitalize} ##{id}
Reported by #{issue[:reporter]} on #{issue[:date]}. Status: #{issue[:status]}
Report: #{issue[:report][0]}
Additional comments:
#{issue[:report].length == 1 ? "  None" : issue[:report][1..-1].map { |r| "  #{r[0]} #{r[1]}"}.join("\n")}
------------------
      END
      end
    end

    def delete_issue type, id
      id = id.to_s
      open_store type, false do |gd|
        if gd.has_key? id
          gd.delete id
          "Deleted #{type} ##{id}."
        else
          "No such #{type} with id #{id}."
        end
      end
    end

    def list_issues type, reporter = nil
      if reporter
        reporter.downcase!
        open_store type do |gd|
          gd.keys.map {|k| k.to_i}.sort.map do |id|
            issue = Marshal.load gd[id.to_s]
            if issue[:reporter].downcase == reporter
              summary issue
            else
              nil
            end
          end.compact.join("\n")
        end
      else
        open_store type do |gd|
          gd.keys.map {|k| k.to_i}.sort.map do |id|
            summary Marshal.load(gd[id.to_s])
          end.join("\n")
        end
      end
    end

    def append_issue type, id, reporter, report
      id = id.to_s
      open_store type, false do |gd|
        if gd.has_key? id
          issue = Marshal.load gd[id]
          issue[:report] << [reporter.capitalize, "(#{Date.today}) #{report}"]
          issue[:updated] = Date.today
          gd[id] = Marshal.dump issue
          "Added your comment to #{type} #{id}."
        else
          "No such #{type} with id #{id}."
        end
      end
    end

    def set_status type, id, reporter, status
      id = id.to_s
      open_store type, false do |gd|
        if gd.has_key? id
          issue = Marshal.load gd[id]
          if status.nil?
            "#{type} #{id} status: #{issue[:status]}."
          else
            status.downcase!
            issue[:report] << [reporter.capitalize, "(#{Date.today}) Changed status from #{issue[:status]} to #{status}."]
            issue[:status] = status
            issue[:updated] = Date.today
            gd[id] = Marshal.dump issue
            "Set status of #{type} #{id} to #{status.downcase}."
          end
        else
          "No such #{type} with id #{id}."
        end
      end
    end

    private

    def summary issue
      if issue[:updated]
        "#{issue[:type]}##{issue[:id]} (#{issue[:status]}) #{issue[:reporter]} #{issue[:date]}: #{issue[:report][0].length > 20 ? "#{issue[:report][0][0..20]}..." : issue[:report][0]} (Updated #{issue[:updated]})"
      else
        "#{issue[:type]}##{issue[:id]} (#{issue[:status]}) #{issue[:reporter]} #{issue[:date]}: #{issue[:report][0].length > 20 ? "#{issue[:report][0][0..20]}..." : issue[:report][0]}"
      end
    end

    def next_id gd
      id = gd.keys.map {|k| k.to_i}.max
      id ||= 0
      (id += 1).to_s
    end

    def open_store type, read_only = true
      file = type.to_s
      if read_only
        flags = GDBM::READER
      else
        flags = GDBM::WRCREAT
      end
      begin
        GDBM.open("storage/admin/" + file, 0666, flags) do |gd|
          yield gd
        end
      rescue Errno::ENOENT
        GDBM.open("storage/admin/" + file, 0666, GDBM::WRCREAT) do |gd|
          yield gd
        end
      end
    end
  end
end
