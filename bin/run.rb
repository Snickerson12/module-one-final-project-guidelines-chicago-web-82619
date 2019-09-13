require_relative '../config/environment'
require 'tty-prompt'
require 'colorize'
require_relative '../db/seeds.rb'

################ CONSTANTS ###############
PROMPT = TTY::Prompt.new(active_color: :bright_white)
##########################################

########## HELPER METHODS - BEG ##########

def welcome
  refresh                   
  message = "Welcome to LolShark, the #1 stats CLI for League of Legends!".colorize(:color => :light_blue).on_light_white
  PROMPT.say(message)
  sleep(2)
end 

def refresh
  system("clear")
  line0 = "                         @@@@@@@@@    \n".colorize(:color => :light_blue)
  line1 = "          @@@@@@@@@@@@@@@@@@@@@@      \n".colorize(:color => :light_blue)
  line2 = "      @@@@@@@@@@@@@@@@@@@@@@@@@       \n".colorize(:color => :light_blue)
  line3 = "    @@@@@@@@@@@@@@@@@@@@@@@@@@@@      \n".colorize(:color => :light_blue)
  line4 = " @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     \n".colorize(:color => :light_blue)
  line5 = " @@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@.   \n".colorize(:color => :light_blue)
  line6 = "         @@@@@@@@  @@@@@@@@@@@@@@@    \n".colorize(:color => :light_blue)
  line7 = "           #@@@@     @@   @@@@@@@@    \n".colorize(:color => :light_blue)
  line8 = "         @@@@@@@           @@@@@@@    \n".colorize(:color => :light_blue)
  line9 = "        @@@@#              @@@@@@     \n".colorize(:color => :light_blue)
  line10 = "       @@.                 @@@@@/     \n".colorize(:color => :light_blue)
  line11 = "      @      @@@        %@@@@@@       \n".colorize(:color => :light_blue)
  line12 = "                @@@     .@@@@@        \n".colorize(:color => :light_blue)
  line13 = "                  @@@@@@@@@@@         \n".colorize(:color => :light_blue)
  line14 = "                   @@@@@(@            \n".colorize(:color => :light_blue)
  line15 = "                   @@@@               \n".colorize(:color => :light_blue)
  line16 = "                   @@@                \n".colorize(:color => :light_blue)
  line17 = "                  @@@                 \n".colorize(:color => :light_blue)
  line18 = "               @@                    \n".colorize(:color => :light_blue)
  shark = line0 + line1 + line2+ line3 + line4 + line5 + line6 + line7 + line8 + line9 + line10 + line11 + line12 + line13 + line14 + line15 + line16 + line17 + line18                             
  line0 = "   _       _     _                _      ".colorize(:color => :white).on_blue    
  line1 = "  | | ___ | |___| |__   __ _ _ __| | __  ".colorize(:color => :white).on_blue
  line2 = "  | |/ _ \\| / __| '_ \\ / _` | '__| |/ /  ".colorize(:color => :white).on_blue
  line3 = "  | | (_) | \\__ \  | | | (_| | |  |   <   ".colorize(:color => :white).on_blue 
  line4 = "  |_|\\___/|_|___/_| |_|\\__,_|_|  |_|\\_\\  ".colorize(:color => :white).on_blue
  ascii = line0 + "\n" + line1 + "\n" + line2 + "\n" + line3 + "\n" + line4 + "\n\n"
  PROMPT.say(shark)
  PROMPT.say(ascii)
end 

def main_menu
  refresh
  greeting = "Please select a search option!"
  PROMPT.select(greeting) do |menu|
    menu.choice "by summoner name", 1
    menu.choice "by champion name", 2
    menu.choice "general stats", 3
    menu.choice "quit", 4
  end
end

def ask_champion_pick_rate(summoner)
  message = "Which champion would you like to know about?"
  champion_name = PROMPT.ask(message, required: true, convert: :string)
  pick_rate = summoner.pick_rate(champion_name)
  PROMPT.say("Hey #{summoner.name}, you pick #{champion_name} #{pick_rate}% of the time.\n\n")
end

def ask_champion_ban_rate(summoner)
  message = "Which champion would you like to know about?"
  champion_name = PROMPT.ask(message, required: true, convert: :string)
  ban_rate = summoner.ban_rate(champion_name)
  PROMPT.say("Hey #{summoner.name}, you ban #{champion_name} #{ban_rate}% of the time.\n\n")
end

def ask_champion_win_rate(summoner)
  message = "Which champion would you like to know about?"
  champion_name = PROMPT.ask(message, required: true, convert: :string)
  win_rate = summoner.win_rate(champion_name)
  PROMPT.say("Hey #{summoner.name}, you win games on #{champion_name} #{win_rate}% of the time.\n\n")
end

def lookup_summoner(summoner_name)
  spinner = TTY::Spinner.new("Locating summoner #{summoner_name} :spinner", format: :dots)
  spinner.auto_spin
  summoner = Summoner.find_by(name: summoner_name)
  if !summoner
    begin  
      accountId = get_account_id(summoner_name)
      matchIds = get_match_ids(accountId)
      matchIds[0..25].each {|matchId| create_match(get_match_data(matchId))}
    rescue
      spinner.stop("Sorry, this summoner name doesn't seem to exist. Please try again.")
      return nil
    end
    create_summoner(summoner_name)
    summoner = Summoner.find_by(name: summoner_name)
  end
  spinner.stop("Summoner found!")
  summoner
end

def search_by_summoner
  refresh
  message = "Please enter a summoner name."
  summoner_name = PROMPT.ask(message, required: true, convert: :string)
  summoner = lookup_summoner(summoner_name)
  if !summoner  
    search_by_summoner 
  end 
  while true  
    instructions = "What would you like to know?"
    choice = PROMPT.select(instructions) do |menu|
      menu.choice "your overall win rate?", 1
      menu.choice "how often you picked a specific champion?", 2
      menu.choice "how often you won with a specific champion?", 3
      menu.choice "how often you ban a specific champion?", 4
      menu.choice "champion you picked the most?", 5
      menu.choice "champion you win the most on?", 6
      menu.choice "champion you ban the most?", 7
      menu.choice "return to main menu", 8
    end
    case choice
    when 1
      win_rate = summoner.overall_win_rate
      PROMPT.say("Hey #{summoner_name}, your win rate is #{win_rate}%.\n\n")
    when 2
      ask_champion_pick_rate(summoner)
    when 3
      ask_champion_win_rate(summoner)
    when 4
      ask_champion_ban_rate(summoner)
    when 5
      most_played = summoner.highest_pick_rate
      PROMPT.say("Hey #{summoner_name}, the champion you pick the most is #{most_played.name} with a #{summoner.pick_rate(most_played.name)}% pick rate.\n\n")
    when 6
      most_wins = summoner.highest_win_rate
      PROMPT.say("Hey #{summoner_name}, the champion you win the most on is #{most_wins.name} with a #{summoner.win_rate(most_wins.name)}% win rate.\n\n")
    when 7
      most_banned = summoner.highest_ban_rate
      PROMPT.say("Hey #{summoner_name}, the champion you ban the most is #{most_banned.name} with a #{summoner.ban_rate(most_banned.name)}% ban rate.\n\n")
    when 8
      break
    else
    end
  end
end

def search_by_champion
  refresh
  message = "Please enter a champion name."
  champion_name = PROMPT.ask(message, required: true, convert: :string)
  champion = Champion.find_by(name: champion_name)
  while true  
    instructions = "What would you like to know?"
    choice = PROMPT.select(instructions) do |menu|
      menu.choice "the champion's overall win rate?", 1
      menu.choice "how often the champion was picked?", 2
      menu.choice "how often the champion was banned?", 3
      menu.choice "return to main menu", 4
    end
    case choice
    when 1
      win_rate = champion.win_rate
      PROMPT.say("#{champion_name} has a #{win_rate}% win rate.\n\n")
    when 2
      pick_rate = champion.pick_rate
      PROMPT.say("#{champion_name} has a #{pick_rate}% pick rate.\n\n")
    when 3
      ban_rate = champion.ban_rate
      PROMPT.say("#{champion_name}, has a ban rate of #{ban_rate}%.\n\n")
    when 4
      break
    else
    end
  end
end

def search_database
  refresh
  while true  
    instructions = "What would you like to know?"
    choice = PROMPT.select(instructions) do |menu|
      menu.choice "the champion with the highest overall win rate?", 1
      menu.choice "the champion with the lowest overall win rate?", 2
      menu.choice "the champion with the highest overall pick rate?", 3
      menu.choice "the champion with the lowest overall pick rate?", 4
      menu.choice "the champion with the highest overall ban rate?", 5
      menu.choice "the champion with the lowest overall ban rate?", 6
      menu.choice "return to main menu", 7
    end
    case choice
    when 1
      winner = Champion.highest_win_rate 
      PROMPT.say("#{winner.name} has the highest win rate with a #{winner.win_rate}% win rate.\n\n")
    when 2
      loser = Champion.lowest_win_rate 
      PROMPT.say("#{loser.name} has the lowest win rate with a #{loser.win_rate}% win rate.\n\n")
    when 3
      winner = Champion.highest_pick_rate 
      PROMPT.say("#{winner.name} is picked the most with a #{winner.pick_rate}% pick rate.\n\n")
    when 4
      loser = Champion.lowest_pick_rate
      PROMPT.say("#{loser.name} is picked the least with a #{loser.pick_rate}% pick rate.\n\n")
    when 5
      most_banned = Champion.highest_ban_rate
      PROMPT.say("#{most_banned.name} is banned the most with a #{most_banned.ban_rate}% ban rate.\n\n")
    when 6
      least_banned = Champion.lowest_ban_rate
      PROMPT.say("#{least_banned.name} is banned the least with a #{least_banned.ban_rate}% ban rate.\n\n")
    when 7
      break
    else
    end
  end
end

########## HELPER METHODS - END ##########
def run
  welcome
  sleep(1)
  while true
    search_method = main_menu
    case search_method
    when 1
      search_by_summoner
    when 2
      search_by_champion
    when 3
      search_database
    when 4
      break
    end
  end
end

run



