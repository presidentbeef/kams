Gem::Specification.new do |s|
  s.name = %q{kams}
  s.version = "0.3.1"
  s.authors = ["Justin Collins"]
  s.summary = "A flexible, basic MUD server"
  s.description = "KAMS provides the basis for building MUDs or other text-based online worlds."
  s.homepage = "http://kingdomsofahln.com/"
  s.files = Dir["resources/**/**"] << "bin/kams"
  s.executables = ["kams"]
  s.add_dependency "eventmachine"
end
