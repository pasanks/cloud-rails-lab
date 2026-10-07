# Health checks for the dashboard. Each check returns a Result with a status:
#
#   :ok      - the resource is attached and working
#   :missing - the resource is not attached (its environment variables are unset)
#   :error   - the resource is attached but something failed (the message is shown)
#
# Every check rescues its own errors, so one broken resource never breaks the page.
module ResourceChecks
  extend self

  Result = Data.define(:name, :status, :details)

  def all
    [ primary_database, secondary_database, cache, sidekiq, bucket ]
  end

  def primary_database
    name = "Primary database"
    # Locally, config/database.yml points at Postgres; on Cloud we need DATABASE_URL.
    return missing(name, "DATABASE_URL" => "not set") if Rails.env.production? && ENV["DATABASE_URL"].blank?

    ok(name, database_details(ApplicationRecord, Note))
  rescue StandardError => e
    error(name, e)
  end

  def secondary_database
    name = "Secondary database"
    return missing(name, "SECONDARY_DATABASE_URL" => "not configured") unless SecondaryRecord.configured?

    ok(name, database_details(SecondaryRecord, SecondaryNote))
  rescue StandardError => e
    error(name, e)
  end

  def cache
    name = "Cache (Redis/Valkey)"
    return missing(name, "REDIS_URL" => "not set", "Rails cache" => "using :memory_store") if ENV["REDIS_URL"].blank?

    # Rails.cache hides connection errors (reads just return nil), so ping first
    # to surface the real error message if the cache is unreachable.
    server = Rails.cache.redis.with(&:info)
    value = SecureRandom.hex(4)
    Rails.cache.write("dashboard-check", value, expires_in: 1.minute)
    raise "Wrote #{value} to the cache but could not read it back" unless Rails.cache.read("dashboard-check") == value

    ok(name,
      "Server" => server["valkey_version"] ? "Valkey #{server["valkey_version"]}" : "Redis #{server["redis_version"]}",
      "URL scheme" => "#{URI(ENV["REDIS_URL"]).scheme}://",
      "Read/write test" => "passed")
  rescue StandardError => e
    error(name, e)
  end

  def sidekiq
    name = "Sidekiq (jobs + cron)"
    return missing(name, "REDIS_URL" => "not set") if ENV["REDIS_URL"].blank?

    details = {
      "Jobs waiting (default queue)" => Sidekiq::Queue.new("default").size,
      "Sidekiq processes alive" => Sidekiq::ProcessSet.new.size,
      "Last job run" => last_job_run
    }
    # Redis works, but no worker process is running to pick jobs up.
    return missing(name, details.merge("Worker" => "no Sidekiq process is running")) if details["Sidekiq processes alive"].zero?

    ok(name, details)
  rescue StandardError => e
    error(name, e)
  end

  def bucket
    name = "Object storage (bucket)"
    vars = %w[AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_BUCKET AWS_ENDPOINT_URL]
    details = vars.to_h { |var| [ var, ENV[var].present? ? "set" : "not set" ] }
    details["Active Storage service in use"] = ActiveStorage::Blob.service.name
    return missing(name, details) unless vars.all? { |var| ENV[var].present? }

    # Test the `cloud` service from config/storage.yml with a real list call.
    service = ActiveStorage::Blob.services.fetch(:cloud)
    response = service.bucket.client.list_objects_v2(bucket: service.bucket.name, max_keys: 5)
    ok(name, details.merge("List call" => "passed (#{response.key_count} objects in first page)"))
  rescue StandardError => e
    error(name, e)
  end

  private

  # Adapter, server version and a row count, for either the primary or secondary database.
  def database_details(base_class, model)
    base_class.with_connection do |connection|
      {
        "Adapter" => connection.adapter_name,
        "Server version" => connection.select_value("SELECT version()"),
        "Database" => connection.current_database,
        "Rows in #{model.table_name}" => model.count
      }
    end
  end

  def last_job_run
    run = JobRun.order(created_at: :desc).first
    run ? "#{run.kind}: #{run.message} at #{run.created_at.utc.strftime("%H:%M:%S UTC")}" : "none yet"
  rescue StandardError => e
    "unavailable (#{e.class})"
  end

  def ok(name, details) = Result.new(name:, status: :ok, details:)
  def missing(name, details) = Result.new(name:, status: :missing, details:)
  def error(name, exception) = Result.new(name:, status: :error, details: { "Error" => "#{exception.class}: #{exception.message}" })
end
