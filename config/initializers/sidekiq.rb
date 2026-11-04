# Sidekiq runs background jobs; sidekiq-cron adds scheduled (cron) jobs on top.
# Both talk to REDIS_URL. redis:// and rediss:// (TLS) URLs both work.
# If REDIS_URL is unset, Sidekiq falls back to localhost:6379 and the dashboard
# shows the queue as "missing".
require "sidekiq/web"
require "sidekiq/cron/web"

Sidekiq.configure_server do |config|
  config.redis = { url: "redis://localhost:6379/0" } # BREAK 17: ignores REDIS_URL
end

Sidekiq.configure_client do |config|
  config.redis = { url: "redis://localhost:6379/0" } # BREAK 17: ignores REDIS_URL
end

# The Sidekiq process loads cron jobs from this file when it boots.
# (This is sidekiq-cron's default path; it's set here so it's easy to find.)
Sidekiq::Cron.configure do |config|
  config.cron_schedule_file = "config/schedule.yml"
end

# The /sidekiq web UI is protected with HTTP basic auth. config/routes.rb only
# mounts it when both SIDEKIQ_USERNAME and SIDEKIQ_PASSWORD are set.
Sidekiq::Web.use Rack::Auth::Basic, "Sidekiq" do |username, password|
  ActiveSupport::SecurityUtils.secure_compare(username, ENV.fetch("SIDEKIQ_USERNAME", "")) &
    ActiveSupport::SecurityUtils.secure_compare(password, ENV.fetch("SIDEKIQ_PASSWORD", ""))
end
