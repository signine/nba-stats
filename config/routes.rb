Rails.application.routes.draw do
  namespace :v1 do
    resource :scoreboard
  end
end
