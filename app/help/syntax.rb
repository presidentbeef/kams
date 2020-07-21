#Used to look up syntax for failed commands to tell the player.
module Syntax

  #Hash of command to syntax help that will be displayed.
  Reference = {
"acarea" =>
"ACAREA [NAME]",
"acdoor" =>
"ACDOOR [DIRECTION] [EXIT_ROOM]",
"acexit" =>
"ACEXIT [DIRECTION] [EXIT_ROOM]",
"acomm" =>
"ACOMMENT [OBJECT] [COMMENT]",
"acomment" =>
"ACOMMENT [OBJECT] [COMMENT]",
"aconfig" =>
"ACONFIG
ACONFIG RELOAD
ACONFIG [SETTING] [VALUE]",
"acopy" =>
"ACOPY [OBJECT]",
"acprop" =>
"ACPROP [GENERIC]",
"acreate" =>
"ACREATE [OBJECT_TYPE] [NAME]",
"acroom" =>
"ACROOM [OUT_DIRECTION] [NAME]",
"adelete" =>
"ADELETE [OBJECT]",
"adesc" =>
"ADESC [OBJECT] [DESCRIPTION]
ADESC INROOM [OBJECT] [DESCRIPTION]",
"aforce" =>
"AFORCE [OBJECT] [ACTION]",
"alearn" =>
"ALEARN [SKILL]",
"ainfo" =>
"AINFO SET [OBJECT] @[ATTRIBUTE] [VALUE]
AINFO DELETE [OBJECT] @[ATTRIBUTE]
AINFO [SHOW|CLEAR] [OBJECT]",
"alist" =>
"ALIST [ATTRIB] [QUERY]",
"alog" =>
"ALOG (DEBUG|NORMAL|HIGH|ULTIMATE|OFF)
ALOG (PLAYER|SERVER|SYSTEM) [LINES]",
"alook" =>
"ALOOK [OBJECT]",
"aput" =>
"APUT [OBJECT] IN [CONTAINER]",
"areact" =>
"AREACT LOAD [OBJECT] [FILE]
AREACT [RELOAD|CLEAR] [OBJECT]",
"areload" =>
"ARELOAD [OBJECT]",
"aset" =>
"ASET [OBJECT] @[ATTRIBUTE] [VALUE]",
"astatus" =>
"ASTATUS",
"ateach" =>
"ATEACH [OBJECT] [SKILL]",
"awho" =>
"AWHO",
"portal" =>
"PORTAL [OBJECT] (ACTION|EXIT|ENTRANCE|PORTAL) [VALUE]",
"terrain" =>
"TERRAIN AREA [TYPE]
TERRAIN HERE TYPE [TYPE]
TERRAIN HERE (INDOORS|WATER|UNDERWATER) (YES|NO)",
"bug" =>
"BUG <issue>
BUG <id number>
BUG LIST
BUG STATUS <id_number> <status>
BUG [SHOW|ADD|DEL] <id_number>",
"idea" =>
"IDEA <issue>
IDEA <id number>
IDEA LIST
IDEA STATUS <id_number> <status>
IDEA [SHOW|ADD|DEL] <id_number>",
"typo" =>
"TYPO <issue>
TYPO <id number>
TYPO LIST
TYPO STATUS <id_number> <status>
TYPO [SHOW|ADD|DEL] <id_number>",
"climb" =>
"What would you like to climb?",
"close" =>
"What would you like to close?",
'crawl' =>
'Where would you like to crawl?',
'delete' =>
'To delete your character, use DELETE ME PLEASE',
'suicide' =>
'To delete your character, use DELETE ME PLEASE',
"drop" =>
"Drop what?",
"emote" =>
"See HELP EMOTES",
"emotelist" =>
"See HELP EMOTELIST",
"get" =>
"Get what?",
"give" =>
"GIVE [OBJECT] TO [PERSON]",
"grab" =>
"Grab what?",
"go" =>
"Go where?",
'jump' =>
'What are you trying to jump over?',
"lock" =>
"What would you like to lock?",
"news" =>
"See HELP NEWS",
"open" =>
"What would you like to open?",
"put" =>
"PUT [OBJECT] IN [CONTAINER]",
"remove" =>
"What would you like to remove?",
'reply' =>
'What would you like to say?',
"say" =>
"You open your mouth but find no words to say.",
"sayto" =>
"SAYTO [PERSON] [MESSAGE]",
"set" =>
"Available settings are: description, wordwrap, pagelength, password, and colors.",
"setdesc" =>
"Please use SET DESC.",
"show" =>
"SHOW COLORS",
"shut" =>
"What would you like to shut?",
"sit" =>
"SIT\nSIT ON [OBJECT]",
"take" =>
"TAKE [OBJECT]\nTAKE [OBJECT] FROM [CONTAINER]",
"tell" =>
"TELL [PERSON] [SOMETHING]",
"unlock" =>
"Unlock what?",
"wear" =>
"What would you like to where?",
"whisper" =>
"WHISPER [PERSON] [MESSAGE]",
"wield" =>
"WIELD [WEAPON] (RIGHT|LEFT)"
}

  #Returns the syntax for the given command or nil if it is not found.
  def Syntax.find(command)
    Reference[command]
  end
end
