#Load this file to require all traits.

Dir.foreach('traits') { |f|
  if f[0,1] == '.' || f[0,1] == '~'
    next
  end

  require "traits/#{f[0..-4]}"
}
