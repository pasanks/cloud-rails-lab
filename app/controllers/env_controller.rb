# Shows which environment variables reach the app. Only GREETING's value is shown;
# everything else is reported as set/unset so no secrets leak.
class EnvController < ApplicationController
  SET_OR_UNSET = %w[
    DATABASE_URL SECONDARY_DATABASE_URL REDIS_URL
    AWS_BUCKET AWS_ENDPOINT_URL AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION
    APP_URL SECRET_KEY_BASE RAILS_ENV PORT
    RAILS_MAX_THREADS WEB_CONCURRENCY
    SIDEKIQ_USERNAME SIDEKIQ_PASSWORD REQUIRED_SETTING
  ].freeze

  def show
    @greeting = ENV["GREETING"]
    @variables = SET_OR_UNSET.to_h { |name| [ name, ENV[name].present? ] }
  end
end
