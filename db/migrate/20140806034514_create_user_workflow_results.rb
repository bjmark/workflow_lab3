class CreateUserWorkflowResults < ActiveRecord::Migration
  def self.up
    create_table :user_workflow_results do |t|
      t.integer  "user_id"
      t.integer  "workflow_result_id"
      t.timestamps
    end
  end

  def self.down
    drop_table :user_workflow_results
  end
end
