Rails.application.routes.draw do
  root "dashboard#show"

  resources :notes, only: %i[index create destroy]
  resources :secondary_notes, only: %i[index create destroy]
  get "env" => "env#show"
  get "cache" => "cache#show"
  delete "cache" => "cache#destroy"
  resources :jobs, only: %i[index create]
  resources :uploads, only: %i[index create destroy]

  # Action Cable (WebSockets) and a page to test it. The page route comes first,
  # because the /cable mount would otherwise also match /cable-test.
  get "cable-test" => "cable_test#show"
  mount ActionCable.server => "/cable"

  # Sidekiq web UI, behind HTTP basic auth (see config/initializers/sidekiq.rb).
  # Disabled unless both credentials are set.
  if ENV["SIDEKIQ_USERNAME"].present? && ENV["SIDEKIQ_PASSWORD"].present?
    mount Sidekiq::Web => "/sidekiq"
  end

  # Break-it routes for testing failures.
  get "boom" => "break_it#boom"
  get "require-env" => "break_it#require_env"
  get "slow" => "break_it#slow"
  get "memory" => "break_it#memory"

  # Health check: 200 if the app boots without exceptions, 500 otherwise.
  # Can be used by load balancers and uptime monitors.
  get "up" => "rails/health#show", as: :rails_health_check
end
