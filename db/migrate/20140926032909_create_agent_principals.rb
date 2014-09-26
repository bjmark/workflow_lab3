class CreateAgentPrincipals < ActiveRecord::Migration
  def self.up
    create_table :agent_principals do |t|
      t.integer  "agent_id"
      t.integer  "principal_id"
      t.date     "start_date"
      t.date     "end_date"

      t.timestamps
    end
  end

  def self.down
    drop_table :agent_principals
  end
end
