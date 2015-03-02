require 'nokogiri'
require 'date'
require 'json'
require 'httparty'

class NBA
  include HTTParty

  BOXSCORE_BASE = "http://www.nba.com/games"
  BOXSCORE_END = "gameinfo.html"
  DEFAULT_OPTS = {"LeagueID" => "00", "DayOffset" => 0}
  ENDPOINTS = {
                scoreboard: "http://stats.nba.com/stats/scoreboard",
                current_scores: "http://data.nba.com/jsonp/10s/json/cms/noseason/scores/gametracker.json?callback=CB&callback=CB"
              }

  def get_scoreboard date
    raise InvalidArgument unless date || date.kind_of?(Date)

    opts = DEFAULT_OPTS.merge({"GameDate" => date.strftime('%m/%d/%Y')})
    response = self.class.get(ENDPOINTS[:scoreboard], query: opts)

    raise "Error code returned: #{response.code}" unless valid? response

    data = JSON.parse response.body
    games = parse_scoreboard data

    games
  end

  def get_current_scores
    response = self.class.get(ENDPOINTS[:current_scores])

    raise "Error code returned: #{response.code}" unless valid? response

    body = response.body
    body = body.slice(3..(body.length - 3))
    data = JSON.parse body

    current_date = Date.strptime(data['sports_content']['dates']['today_date'], '%Y%m%d')
    return get_scoreboard(now)  unless today? current_date

    games = parse_current_scores data

    games
  end

  private

  def parse_current_scores data
    games = []
    current_date = data['sports_content']['dates']['today_date']
    current_games = data['sports_content']['game'].select { |g| g['date'] == current_date }
    current_games.each do |g|
      game = {}
      game[:id] = g['id']
      game[:status] = g['period_time']['period_status']
      game[:time] = g['period_time']['game_clock']
      game[:boxscore_link] = make_boxscore_link(g['game_url']) 

      game[:team_1] = g['visitor']['team_key'] 
      game[:team_1_score] = g['visitor']['score']

      game[:team_2] = g['home']['team_key'] 
      game[:team_2_score] = g['home']['score']

      games << game
    end

    games
  end

  def parse_scoreboard data
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

  def now
    DateTime.now.in_time_zone
  end

  def today? date
    now == date
  end
end
