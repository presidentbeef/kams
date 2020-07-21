#Just some custom errors.
module MUDError

  #Raised when an unknown character name is entered.
  class UnknownCharacter < RuntimeError; end

  #Raised when a wrong password is entered when logging in.
  class BadPassword < RuntimeError; end

  #Raised when a character is already loaded.
  class CharacterAlreadyLoaded < RuntimeError; end

  #Raised when a GOID cannot be found in the list of GOIDs that
  #records where a GOID is stored.
  class NoSuchGOID < RuntimeError; end

  #Raised when an object comes back as nil when attempting to load it.
  class ObjectLoadError < RuntimeError; end

  #Raised to shutdown server from within game.
  class Shutdown < RuntimeError; end
end

