class CreateWorkflowResults < ActiveRecord::Migration
  def self.up
    create_table :workflow_results do |t|
      t.string   "wfid"
      t.string   "result"
      t.integer  "final_user_id"
      t.datetime "process_at"
      t.string   "target_type"
      t.integer  "target_id"
      t.integer  "workflow_id"
      t.boolean  "finished",      :default => false
      t.text     "snapshot"
      t.timestamps
    end
  end

  def self.down
    drop_table :workflow_results
  end
end
