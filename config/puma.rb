# Puma configuration for Laravel Cloud (and local development).
# See https://cloud.laravel.com/docs/deploy-guides/ruby#configure-puma-concurrency

# Threads per process. Each thread needs its own database connection, so
# config/database.yml uses the same RAILS_MAX_THREADS value for its pool.
thread_count = Integer(ENV.fetch("RAILS_MAX_THREADS", "3"))
threads thread_count, thread_count

# 0 = single process (no clustered workers). Raise it once you know the memory usage.
workers Integer(ENV.fetch("WEB_CONCURRENCY", "0"))

# Cloud's startup probes connect over IPv6, so listen on [::] (all interfaces).
# This must be the ONLY listener: no other `port` or `bind` lines.
bind "tcp://[::]:#{ENV.fetch('PORT', '3000')}"

# Keep these shorter than the environment's graceful shutdown timeout,
# so in-flight requests can finish after Cloud sends SIGTERM.
force_shutdown_after 20
worker_shutdown_timeout 25

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart
