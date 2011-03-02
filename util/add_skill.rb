require 'yaml'
require 'lib/combatskill'

if File.exist? "lib/combat_skill.yaml"
  skills = YAML.load("lib/combat_skill.yaml")
else
  skills = {}
end

skill = CombatSkill.new

loop do
  puts "Name:"
  skill.name = gets.chomp
  puts "Command:"
  skill.command = gets.chomp.downcase.to_sym
  puts "Learning points:"
  skill.learning_points = gets.chomp.to_i
  puts "Damage:"
  skill.damage = gets.chomp.to_i
  puts "Delay:"
  skill.delay = gets.chomp.to_f
  puts "Method type (generic|special):"
  skill.method_type = gets.chomp.downcase.to_sym
  puts "Skill type (attack, block, evade, etc.):"
  skill.skill_type = gets.chomp.downcase.to_sym
  puts "Start message player:"
  skill.start_msg_player = gets.chomp
  puts "Start message target:"
  skill.start_msg_target = gets.chomp
  puts "Start message room:"
  skill.start_msg_room = gets.chomp
  puts "Success message player:"
  skill.succ_msg_player = gets.chomp
  puts "Success message target:"
  skill.succ_msg_target = gets.chomp
  puts "Success message room:"
  skill.succ_msg_room = gets.chomp
  puts "Fail message player:"
  skill.fail_msg_player = gets.chomp
  puts "Fail message target:"
  skill.fail_msg_target = gets.chomp
  puts "Fail message room:"
  skill.fail_msg_room = gets.chomp
  puts "Description:"
  skill.description = gets.chomp

  skills[skill.command] = skill

  File.open("lib/combat_skill.yaml", "w") { |f| YAML.dump(skills, f) }

  puts "More (y/n):"
  break if gets.chomp.downcase[0,1] == 'n'
end

