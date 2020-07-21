require 'ostruct'

#Info is a nice class for storing information about...anything.
#It is like OpenStruct[http://ruby-doc.org/stdlib/libdoc/ostruct/rdoc/classes/OpenStruct.html] (in fact, a subclass of it) except it is easy to set, retrieve, and delete items using Strings even for nested keys.
#However, it is not much smarter than that, so if you want it to have nested keys, you will need to initialize those nested Infos by hand.
#
#===Example
#
# person = Info.new
# person.name = "Bob"
# person.address.state = "WA" => #NoMethodError: undefined method `state=' for nil:NilClass
# person.address = Info.new
# person.address.state = "WA"
# person.get("address.state") => "WA"
#
#Note that #get, #set, and #delete are primarily there to make Admin commands easy.
#When programming with an Info object, it would typically be treated just like an OpenStruct.
#
#===Note
#
#Every GameObject has an Info attribute called info.
#The info attributes used in the class are listed in the documentation for these classes.
class Info < OpenStruct

  #Creates a new Info object. If a hash is given, the Info will be initialized with the keys (Strings or Symbols)
  #as attributes and the values as values. Note that this will not work for nested keys.
  def initialize(hash = nil)
    super
  end

  #Sets an attribute to a given value. Creates the attribute if it does not already exist.
  #If attrib is a symbol, it cannot reference a nested key. For example, :this.this.that will not work,
  #but "this.this.that" will.
  #
  # info = Info.new
  # info.set("name", Info.new)
  # info.set("name.first", "bob")
  # info.set("name.last", "jone")
  def set attrib, value
    if attrib.is_a? String and attrib.include? "."
      syms = attrib.split(".")
      first = syms[0]
      rest = syms[1..-1].join(".")
      self.send(first).set(rest, value)
    else
      self.send("#{attrib}=".to_sym, value)
    end
  end

  #Retrieves a value by its name.
  def get attrib
    if attrib.is_a? String and attrib.include? "."
      syms = attrib.split(".")
      first = syms[0]
      rest = syms[1..-1].join(".")
      self.send(first).get(rest)
    else
      self.send(attrib.to_sym)
    end
  end

  #Deletes an attribute by name.
  def delete attrib
    if attrib.is_a? String and attrib.include? "."
      syms = attrib.split(".")
      first = syms[0]
      rest = syms[1..-1].join(".")
      self.send(first).delete(rest)
    else
      self.delete_field(attrib)
    end
  end

  #Slightly modified, slightly less safe version from OpenStruct. So don't point an Info object to itself.
  def inspect(key = "")
    str = "Info:\n"
    Thread.current[InspectKey] ||= []
    for k,v in @table
      Thread.current[InspectKey] << v
      begin
        if v.is_a? Info
          str << "#{key}#{k}: #{v.inspect(" #{k}.")}\n"
        else
          str << "#{key}#{k}: #{v.inspect}\n"
        end
      ensure
        Thread.current[InspectKey].pop
      end
    end
    str
  end

  def to_s
    "Info object"
  end
end
