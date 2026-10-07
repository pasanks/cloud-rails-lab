class CreateJobRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :job_runs do |t|
      t.string :kind
      t.string :message
      t.string :hostname
      t.integer :duration_ms

      t.timestamps
    end
  end
end
