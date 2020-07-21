#Borrowed from:
#
#Florian Frank mailto:flori@ping.de
#
#== License
#
#This is free software; you can redistribute it and/or modify it under the
#terms of the GNU General Public License Version 2 as published by the Free
#Software Foundation: www.gnu.org/copyleft/gpl.html
#
#== Download
#
#The latest version of this library can be downloaded at
#
#* http://rubyforge.org/frs?group_id=391
#
#The homepage of this library is located at
#
#* http://term-ansicolor.rubyforge.org
#
#ANSI colors.
module Color
  @@attributes = [
  [ :clear        ,   0 ],
  [ :reset        ,   0 ],     # synonym for :clear
  [ :bold         ,   1 ],
  [ :dark         ,   2 ],
  [ :italic       ,   3 ],     # not widely implemented
  [ :underline    ,   4 ],
  [ :underscore   ,   4 ],     # synonym for :underline
  [ :blink        ,   5 ],
  [ :rapid_blink  ,   6 ],     # not widely implemented
  [ :negative     ,   7 ],     # no reverse because of String#reverse
  [ :concealed    ,   8 ],
  [ :strikethrough,   9 ],     # not widely implemented
  [ :black        ,  30 ],
  [ :red          ,  31 ],
  [ :green        ,  32 ],
  [ :yellow       ,  33 ],
  [ :blue         ,  34 ],
  [ :magenta      ,  35 ],
  [ :cyan         ,  36 ],
  [ :white        ,  37 ],
  [ :on_black     ,  40 ],
  [ :on_red       ,  41 ],
  [ :on_green     ,  42 ],
  [ :on_yellow    ,  43 ],
  [ :on_blue      ,  44 ],
  [ :on_magenta   ,  45 ],
  [ :on_cyan      ,  46 ],
  [ :on_white     ,  47 ],
  ]

  # Returns true, if the coloring function of this module
  # is switched on, false otherwise.
  def self.coloring?
    @@coloring
  end

  # Turns the coloring on or off globally, so you can easily do
    # this for example:
    #  Term::ANSIColor::coloring = STDOUT.isatty
    def self.coloring=(val)
      @@coloring = val
    end
    self.coloring = true

    @@attributes.each do |c, v|
      eval %Q{
        def #{c}(string = nil)
          result = ''
          result << "\e[#{v}m" if @@coloring
          if block_given?
            result << yield
          elsif string
            result << string
          elsif respond_to?(:to_str)
            result << self
          else
            return result #only switch on
          end
          result << "\e[0m" if @@coloring
          result
        end
      }
    end

    # Regular expression that is used to scan for ANSI-sequences. It is used to
    # uncolor strins.
    COLORED_REGEXP = /\e\[([34][0-7]|[0-9])m/

    # Returns an uncolored version of the string, that is all
    # ANSI-sequences are stripped from the string.
    def uncolored(string = nil) # :yields:
      if block_given?
        yield.gsub(COLORED_REGEXP, '')
      elsif string
        string.gsub(COLORED_REGEXP, '')
      elsif respond_to?(:to_str)
        gsub(COLORED_REGEXP, '')
      else
        ''
      end
    end

    module_function

    # Returns an array of all Term::ANSIColor attributes as symbols.
    def attributes
      @@attributes.map { |c| c.first }
    end
    extend self
  end
