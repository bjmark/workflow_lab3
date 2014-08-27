class CreateWorkflows < ActiveRecord::Migration
  def self.up
    create_table :workflows do |t|
      t.text     "definition",   :null => false
      t.string   "name",         :null => false
      t.string   "code",         :null => false
      t.string   "target_model", :null => false
      t.string   "version",      :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :workflows
  end
end
