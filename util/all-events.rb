#Load this file to require all event modules.

Dir.foreach('events') { |f|
  if f[0,1] == '.' || f[0,1] == '~'
    next
  end
  
  require "events/#{f[0..-4]}"
}
