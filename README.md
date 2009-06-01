## Kingdoms of Ahln MUD Server (kams)

Author: Justin Collins  
License: GPLv2 except where noted  
Website: <http://kingdomsofahln.com>

### Requires

[Ruby](http://ruby-lang.org/) (1.8.6, 1.8.7, or 1.9.1)

[EventMachine](http://rubyeventmachine.com/)

### Installation

1. `gem install eventmachine`
2. Uncompress the kams source somewhere
3. Run `ruby util/setup.rb`
4. Run `ruby server.rb`

If you are using the Windows Ruby One-Click Installer, you can double-click setup.rb and server.rb to run them.

### Where to find things

The Server starts and restarts the server.

The Manager holds all the GameObjects, passes events to the EventHandler, and generally holds methods for accessing the state of the game.

GameObject is the superclass of all objects in the game.

Player handles player stuff, like showing the prompt and managing stats.

CommandParser turns commands into events.

EventHandler calls the appropriate events.

StorageMachine stores GameObjects in the storage/ directory (by default).

All game objects should be kept in the objects/ directory.

The text shown upon connection is in the intro.txt file and is loaded by the PlayerConnection if it exists.

'Reactions' for GameObjects are in objects/reactions/ and have the '.rx' extension.

Help files go in help/ and are just plain text files with the '.help' extension. You can simply use symbolic links for aliasing one command to another.

The file help/syntax.rb provides syntax help in the game.

### Beware

Some things (hunger) may appear to be implemented but they really are not.
