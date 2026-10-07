# Base class for models stored in the optional secondary database.
#
# This connection is deliberately NOT in config/database.yml. Instead we connect
# at runtime to SECONDARY_DATABASE_URL, which can be a postgresql:// or mysql2://
# URL. That lets one environment use Postgres and MySQL side by side.
#
# Its tables are created by `bin/rails db:secondary:prepare` (lib/tasks/secondary.rake).
class SecondaryRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.configured?
    ENV["SECONDARY_DATABASE_URL"].present?
  end

  # When the variable is unset we don't connect at all. Controllers check
  # `configured?` first, because an abstract class without its own connection
  # would otherwise silently use the primary database.
  establish_connection(ENV["SECONDARY_DATABASE_URL"]) if configured?
end
