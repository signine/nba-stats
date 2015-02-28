require 'date'
require 'json'
require 'httparty'

class NBA
  include HTTParty

  base_uri "http://stats.nba.com/stats/"

  DEFAULT_OPTS = {"LeagueID" => "00", "DayOffset" => 0}
  ENDPOINTS = {scoreboard: '/scoreboard'}
  # http://stats.nba.com/stats/scoreboard?LeagueID=00&DayOffset=0&GameDate=01/22/2015

  def get_scoreboard date
    raise InvalidArgument unless date || date.kind_of?(Date)

    opts = DEFAULT_OPTS.merge({"GameDate" => date.strftime('%m/%d/%Y')})
    response = self.class.get(ENDPOINTS[:scoreboard], query: opts)

    if valid? response
      JSON.parse response.body
    else
      raise "Error code returned: #{response.code}"
    end
  end

  private

  def valid? resp
    resp.code == 200
  end
end
