# Enqueued from the /jobs page. Sleeps to simulate slow work, then records a JobRun.
class SlowJob < ApplicationJob
  queue_as :default

  def perform(seconds = 5)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    logger.info "[SlowJob] Sleeping #{seconds}s on #{ProcessInfo.hostname}"
    sleep seconds

    duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
    JobRun.create!(kind: "manual", message: "Slept #{seconds}s", hostname: ProcessInfo.hostname, duration_ms: duration_ms)
    logger.info "[SlowJob] Finished in #{duration_ms}ms"
  end
end
