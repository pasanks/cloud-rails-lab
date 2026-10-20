# Routes that fail on purpose, for testing logs, error pages, timeouts and memory limits.
class BreakItController < ApplicationController
  # GET /boom - raises an exception (500 page + stack trace in the logs).
  def boom
    raise "Boom! This is a deliberate exception from /boom."
  end

  # GET /require-env - raises KeyError unless REQUIRED_SETTING is set.
  def require_env
    value = ENV.fetch("REQUIRED_SETTING")
    render plain: "REQUIRED_SETTING is set (#{value.length} characters)."
  end

  # GET /slow?seconds=N - sleeps N seconds before responding (default 5).
  def slow
    seconds = params.fetch(:seconds, 5).to_f
    sleep seconds
    render plain: "Slept #{seconds} seconds."
  end

  # GET /memory?mb=N - allocates N megabytes (default 100) during the request.
  def memory
    megabytes = params.fetch(:mb, 100).to_i
    chunks = Array.new(megabytes) { "x" * 1.megabyte }
    render plain: "Allocated #{chunks.size} MB. Process memory (RSS) is now #{ProcessInfo.rss_mb} MB."
  end
end
