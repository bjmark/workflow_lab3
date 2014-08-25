class CreateProjects < ActiveRecord::Migration
  def self.up
    create_table :projects do |t|
      t.string :name
      t.integer  "handler_id"
      t.integer  "cohandler_id"
      t.integer  "workflow_status_id"
      t.text     "hhash"

      t.timestamps
    end
  end

  def self.down
    drop_table :projects
  end
end
