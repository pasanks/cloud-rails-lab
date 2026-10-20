# BREAK 05: require an environment variable while the app boots (every process,
# every rake task), unlike /require-env which only fails on request.
ENV.fetch("REQUIRED_AT_BOOT")
