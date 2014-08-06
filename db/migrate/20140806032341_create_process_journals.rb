class CreateProcessJournals < ActiveRecord::Migration
  def self.up
    create_table :process_journals do |t|
      t.integer  "workflow_id"
      t.integer  "user_id"
      t.integer  "as_role_id"
      t.text     "comments"
      t.integer  "owner_id"
      t.string   "owner_type"
      t.boolean  "ok"
      t.string   "wfid"
      t.text     "original_tree"
      t.text     "current_tree"
      t.string   "workflow_action"
      t.timestamps
    end
  end

  def self.down
    drop_table :process_journals
  end
end
