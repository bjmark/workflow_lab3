class CreateCashPositions < ActiveRecord::Migration
  def self.up
    create_table :cash_positions do |t|
      t.string "name"
      t.integer  "project_id"
      t.integer  "workflow_status_id"
      t.timestamps
    end
  end

  def self.down
    drop_table :cash_positions
  end
end
