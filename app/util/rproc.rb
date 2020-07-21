require 'util/log'

#This is basically an adaptation of a serializable (kinda) Proc. The binding is
#not serializable, but then again it doesn't really need to be, does it?
#
#Used for reactions.
class RProc

  attr_accessor :source

  #Pass in the string to be turned into a Proc. This should only be the
  #inner code.
  #
  #For example:
  #
  #"puts \"hello there, #{event[:player].name}\""
  def initialize(code)
    @source = code
    @lambda = nil
  end

  #Converts to a Proc so it can be called like one. Resulting Proc is cached.
  def to_proc
    if @lambda.nil?
      @lambda = lambda { |event, player, room, mob| mob.instance_eval(@source) }
    else
      @lambda
    end
  end

  #Forwards methods to Proc.
  def method_missing(*args)
    to_proc.send(*args)
  end

  #Dumps source.
  def marshal_dump
    @source
  end

  #Loads source.
  def marshal_load(code)
    initialize(code)
  end
end
