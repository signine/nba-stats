require 'json'
require 'date'

class ScoreboardController << ApplicationController
  def index
    begin
      dates = parse_dates params['dates']
    rescue 
      error("Invalid or missing dates", 422) and return unless dates
    end

    games = []
    dates.each { |d| games << get_scoreboard(d) }

    render :json => {scoreboard: games}
  end


  private

  def get_scoreboard date


  end

  def parse_dates dates
    raise Exception, 'Dates missing' unless dates
    
    dates = JSON.parse(dates)
    dates.each! { |d| Date.strptime(d, '%m/%d/%Y') }

    dates
  end
end
