# THIS IS WHERE WE GET API DATA
require 'rest-client'
require 'json'
require 'pry'
require_relative "../config/environment.rb"

############ CONSTANTS ############
API_KEY = "RGAPI-42a2e83d-6765-4793-8d65-6e7420b2cd61"
REGION = 'na1'
PATCH_NUMBER = '9.17.1'
TIER = 'SILVER'
DIVISION = 'I'
###################################

############ METHODS ############
#return hash of all data for each champion
def get_champion_data(patch_number)
  response_string = RestClient.get("http://ddragon.leagueoflegends.com/cdn/#{patch_number}/data/en_US/champion.json")
  response_hash = JSON.parse(response_string)
  champion_data = response_hash["data"]
end

#create all Champion objects with champion_data
def create_champions(champion_data)
  champions = champion_data.keys
  champions.each do |champion|
    key = champion_data[champion]["key"]
    champion_name = champion_data[champion]["name"]
    Champion.create(champ_id: key, name: champion_name)
  end
end

#returns a list of summoner names
def get_summoner_names
  # Make an API request for all summoners in a ranked division.
  response_string = RestClient.get("https://#{REGION}.api.riotgames.com/lol/league/v4/entries/RANKED_SOLO_5x5/#{TIER}/#{DIVISION}?page=1&api_key=#{API_KEY}")
  #sleep(1)
  summoner_data = JSON.parse(response_string)
  # For each summoner whose data is in summoner_data, return their name.
  summoner_names = summoner_data.map do |summoner| 
    summoner_name = summoner["summonerName"].gsub(" ", "%20").encode("ASCII", invalid: :replace, undef: :replace)
  end.delete_if {|name| name.include?('?')}
end

#Using the summoner name, create a Summoner
def create_summoner(summoner_name)
  Summoner.find_or_create_by(name: summoner_name)
end

#Using the summoner name, return single account id
def get_account_id(summoner_name)
  # Given the summoner's name, make an API request for account information.
  url = "https://#{REGION}.api.riotgames.com/lol/summoner/v4/summoners/by-name/#{summoner_name}?api_key=#{API_KEY}"
  response_string = RestClient.get(url)
  #sleep(1)
  # The JSON object contains summoner account information. Return the accountId.
  summoner_account_info = JSON.parse(response_string)
  account_id = summoner_account_info["accountId"]
end

#returns an array of match ids given an account id
def get_match_ids(account_id)
  # Given a summoner's accountId, make an API request for their match history.
  url = "https://#{REGION}.api.riotgames.com/lol/match/v4/matchlists/by-account/#{account_id}?api_key=#{API_KEY}"
  response_string = RestClient.get(url)
  #sleep(1)
  match_history = JSON.parse(response_string)
  match_ids = match_history["matches"].map {|match| match['gameId']}.uniq
end

#returns match data given a single match id
def get_match_data(match_id)
  # Given a matchId, make an API request for the match data.
  url = "https://#{REGION}.api.riotgames.com/lol/match/v4/matches/#{match_id}?api_key=#{API_KEY}"
  response_string = RestClient.get(url)
  sleep(1)
  match_data = JSON.parse(response_string)
end

#Given match data, creates a Match object for each player in the match.
def create_match(match_data)
  participants = match_data["participantIdentities"]
  for participant in participants do
    # Create a new Match object.
    match = Match.new
    # Set the Match's summoner_id field.
    summoner = create_summoner(participant["player"]["summonerName"])
    match.summoner_id = summoner.id
    # Set the Match's champion_id and win field.
    participant_data = match_data["participants"]
    current_summoner = participant_data.find do |data|
      data["participantId"] == participant["participantId"]
    end
    match.champion_id = Champion.find_by(champ_id: current_summoner["championId"]).id
    match.win = current_summoner["stats"]["win"]
    # Set the Match's game_id field.
    match.game_id = match_data["gameId"]
    # Set the Match's ban field.
    bans = match_data["teams"][0]["bans"] + match_data["teams"][1]["bans"]
    if bans.empty?
      match.ban = -1
    else
      match.ban = bans.find {|ban| ban["pickTurn"] == participant["participantId"]}["championId"]
    end
      # Save the Match to the database!
    match.save
  end
end
#################################
def seed
  #Create Champion objs.
  # create_champions(get_champion_data(PATCH_NUMBER))
  #1st - Get a list of summoner names.
  names = get_summoner_names
  #2nd - Get the encrypted account_ids for each summoner.
  account_ids = names.map {|name| get_account_id(name)}
  #3rd - Get the matchIds for that accountId.
  match_ids = account_ids.map {|accountId| get_match_ids(accountId)}.flatten
  print "#{match_ids.size} number of matches found!"
  #4th - Create a match object for each matchId.
  for match_id in match_ids do
    begin  
      create_match(get_match_data(match_id)) 
      raise 'probably HTTP error'
    rescue
      redo
    end 
  end
end

#seed