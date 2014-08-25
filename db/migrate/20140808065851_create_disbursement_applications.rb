class CreateDisbursementApplications < ActiveRecord::Migration
  def self.up
    create_table :disbursement_applications do |t|
      t.string :name
      t.integer  "workflow_status_id"
      t.integer "cash_position_id"
      t.text     "hhash"
      t.timestamps
    end
  end

  def self.down
    drop_table :disbursement_applications
  end
end
