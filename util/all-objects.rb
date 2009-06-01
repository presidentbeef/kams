#Load this file to require all objects.

Dir.glob('objects/*.rb').each { |f|
	require f[0..-4] unless  f[0,1] == '~'
}
