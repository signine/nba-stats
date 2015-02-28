require 'date'
require 'json'
require 'httparty'

class NBA
  include HTTParty

  base_uri "http://stats.nba.com/stats/"

  BOXSCORE_BASE = "http://www.nba.com/games"
  BOXSCORE_END = "gameinfo.html"
  DEFAULT_OPTS = {"LeagueID" => "00", "DayOffset" => 0}
  ENDPOINTS = {scoreboard: '/scoreboard'}

  def get_scoreboard date
    raise InvalidArgument unless date || date.kind_of?(Date)

    opts = DEFAULT_OPTS.merge({"GameDate" => date.strftime('%m/%d/%Y')})
    response = self.class.get(ENDPOINTS[:scoreboard], query: opts)

    raise "Error code returned: #{response.code}" unless valid? response

    data = JSON.parse response.body
    games = parse_games data

    games
  end

  private

  def parse_games data
    games = []

    data['resultSets'][0]['rowSet'].each do |g|
      game = {}
      game[:id] = g[2]
      game[:status] = g[4]
      game[:time] = g[10]
      game[:boxscore_link] = make_boxscore_link(g[5]) 

      line_scores = get_linescores data, game[:id]

      game[:team_1] = line_scores[0][4]
      game[:team_1_score] = line_scores[0][21]

      game[:team_2] = line_scores[1][4]
      game[:team_2_score] = line_scores[1][21]

      games << game
    end

    games
  end

  def make_boxscore_link game_code
    "#{BOXSCORE_BASE}/#{game_code}/#{BOXSCORE_END}"
  end

  def get_linescores data, game_id
    data['resultSets'][1]['rowSet'].select { |g| g[2] == game_id }
  end

  def valid? resp
    resp.code == 200
  end
end
