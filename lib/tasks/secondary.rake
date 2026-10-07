# Prepares the optional secondary database (see app/models/secondary_record.rb).
#
#   bin/rails db:secondary:prepare
#
# Safe to run on every deploy: it does nothing when SECONDARY_DATABASE_URL is
# unset, and uses CREATE TABLE IF NOT EXISTS so it can run repeatedly.
namespace :db do
  namespace :secondary do
    desc "Create the secondary_notes table in SECONDARY_DATABASE_URL (skipped when unset)"
    task prepare: :environment do
      unless SecondaryRecord.configured?
        puts "SECONDARY_DATABASE_URL is not set, skipping the secondary database."
        next
      end

      SecondaryRecord.with_connection do |connection|
        # Generates CREATE TABLE IF NOT EXISTS for Postgres and MySQL alike.
        connection.create_table :secondary_notes, if_not_exists: true do |t|
          t.string :title, null: false
          t.text :body
          t.timestamps
        end

        puts "secondary_notes is ready (#{connection.adapter_name}, database #{connection.current_database})."
      end
    end
  end
end
