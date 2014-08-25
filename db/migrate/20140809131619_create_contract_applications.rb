class CreateContractApplications < ActiveRecord::Migration
  def self.up
    create_table :contract_applications do |t|
      t.string   "name"
      t.integer  "financial_term_id"
      t.integer  "workflow_status_id",           :default => 1, :null => false
      t.integer  "user_id"
      t.timestamps
    end
  end

  def self.down
    drop_table :contract_applications
  end
end
