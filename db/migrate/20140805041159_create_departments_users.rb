class CreateDepartmentsUsers < ActiveRecord::Migration
  def self.up
    create_table "departments_users", :id => false, :force => true do |t|
      t.integer "department_id"
      t.integer "user_id"
    end
  end

  def self.down
    drop_table :departments_users
  end
end
