class CreateWorkflowStatuses < ActiveRecord::Migration
  def self.up
    create_table :workflow_statuses do |t|
      t.string "name"
      t.string "code"
    end
  end

  def self.down
    drop_table :workflow_statuses
  end
end
