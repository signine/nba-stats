Rails.application.routes.draw do
  namespace :v1 do
    resource :scoreboard do
      get 'current_scores', on: :collection
    end
  end
end
