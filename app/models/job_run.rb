# One row per background job run: SlowJob writes kind "manual", HeartbeatJob writes kind "cron".
class JobRun < ApplicationRecord
  scope :recent, -> { order(created_at: :desc).limit(20) }
end
