# BREAK 04: simulate a slow boot in production, to see how long Cloud's startup
# probe waits. Runs last (initializers load alphabetically). Tune with BOOT_SLEEP.
sleep Integer(ENV.fetch("BOOT_SLEEP", "30")) if Rails.env.production?
