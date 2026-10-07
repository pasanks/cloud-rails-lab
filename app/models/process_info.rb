# Facts about the current Ruby process (each Puma or Sidekiq process has its own).
module ProcessInfo
  extend self

  # Set in config/initializers/boot_time.rb. A recent boot time after a quiet
  # period means this instance was cold-started (e.g. after scale-to-zero).
  def booted_at
    Rails.application.config.x.booted_at
  end

  def hostname
    Socket.gethostname
  end

  def pid
    Process.pid
  end

  # Resident memory in MB. Linux (Cloud) has /proc; macOS falls back to `ps`.
  def rss_mb
    if File.exist?("/proc/self/status")
      File.read("/proc/self/status")[/VmRSS:\s+(\d+)/, 1].to_i / 1024
    else
      `ps -o rss= -p #{Process.pid}`.to_i / 1024
    end
  end
end
