require 'json'
require 'date'

module V1
  class ScoreboardsController < ApplicationController
    def show 
      begin
        dates = parse_dates params['dates']
      rescue 
        error("Invalid or missing dates", 422) and return unless dates
      end
  
      games = []
      dates.each { |d| games << get_scoreboard(d) }
  
      render :json => {scoreboard: games}
    end

    def current_scores
      render :json => {current_scores: get_current_scores}
    end


    private

    def get_current_scores
      Rails.cache.fetch("current_scores", expires_in: 15.seconds) do
        nba = NBA.new
        nba.get_current_scores
      end
    end
  
    def get_scoreboard date
      return get_current_scores if today? date

      key = "scoreboard-#{date.strftime('%m/%d/%Y')}"
  
      Rails.cache.fetch(key, expires_in: 1.day) do
        nba = NBA.new
        nba.get_scoreboard date
      end
    end
  
    def parse_dates dates
      raise Exception, 'Dates missing' unless dates
      
      dates = JSON.parse(dates)
      dates.map! { |d| Date.strptime(d, '%m/%d/%Y') }
  
      dates
    end

    def today? date
      Time.now.to_date == date
    end

  end
end
