# Enqueue SlowJob into Sidekiq and list recent job runs (manual and cron).
class JobsController < ApplicationController
  def index
    @job_runs = JobRun.recent
  end

  def create
    seconds = params.fetch(:seconds, 5).to_i.clamp(1, 60)
    job = SlowJob.perform_later(seconds)
    redirect_to jobs_path, notice: "Enqueued SlowJob #{job.job_id} (#{seconds}s). Refresh to see it finish."
  end
end
