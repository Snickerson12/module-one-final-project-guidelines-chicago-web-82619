class Champion < ActiveRecord::Base
  has_many :matches
  has_many :summoners, through: :matches

  def pick_rate
    matches_total = Match.all.count/10.0
    matches_picked = self.matches.count
    (matches_picked/matches_total*100).round(2)
  end

  def win_rate
    matches_picked = self.matches.count.to_f
    matches_won = Match.where(win: true, champion_id: self.id).count
    (matches_won/matches_picked*100).round(2)
  end

  def self.highest_pick_rate
    champion = self.all.max_by {|champion| champion.pick_rate}
    puts "The champion with the highest pick rate is #{champion.name} with a #{champion.pick_rate}% pick rate."
  end

  def self.lowest_pick_rate
    champion = self.all.min_by {|champion| champion.pick_rate}
    puts "The champion with the lowest pick rate is #{champion.name} with a #{champion.pick_rate}% pick rate."
  end

  def self.highest_win_rate
    champion = self.all.max_by {|champion| champion.win_rate}
    puts "The champion with the highest win rate is #{champion.name} with a #{champion.win_rate}% win rate."
  end

  def self.lowest_win_rate
    champion = self.all.min_by {|champion| champion.win_rate}
    puts "The champion with the lowest win rate is #{champion.name} with a #{champion.win_rate}% win rate."
  end


end