class CreateWorkflows < ActiveRecord::Migration
  def self.up
    create_table :workflows do |t|
      t.text     "definition", :null => false
      t.string   "name"
      t.timestamps
    end
  end

  def self.down
    drop_table :workflows
  end
end
