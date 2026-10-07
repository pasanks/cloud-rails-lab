# Runs every minute via sidekiq-cron (config/schedule.yml), to prove scheduled
# tasks work on Cloud without a separate scheduler.
class HeartbeatJob < ApplicationJob
  queue_as :default

  def perform
    JobRun.create!(kind: "cron", message: "Heartbeat", hostname: ProcessInfo.hostname, duration_ms: 0)
    logger.info "[HeartbeatJob] Heartbeat from #{ProcessInfo.hostname}"
  end
end
