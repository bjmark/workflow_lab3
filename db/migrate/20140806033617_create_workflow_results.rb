class CreateWorkflowResults < ActiveRecord::Migration
  def self.up
    create_table :workflow_results do |t|
      t.string   "workflow_name"
      t.string   "wfid"
      t.string   "target"
      t.string   "result"
      t.integer  "final_user_id"
      t.string   "project"
      t.datetime "process_at"
      t.string   "target_type"
      t.integer  "target_id"
      t.string   "ok",            :limit => 1
      t.string   "finish",        :limit => 1
      t.timestamps
    end
  end

  def self.down
    drop_table :workflow_results
  end
end
