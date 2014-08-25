class CreateWorkflowLogs < ActiveRecord::Migration
  def self.up
    create_table :workflow_logs do |t|
      t.string 'message'
      t.timestamps
    end
  end

  def self.down
    drop_table :workflow_logs
  end
end
