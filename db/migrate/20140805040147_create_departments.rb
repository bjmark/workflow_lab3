class CreateDepartments < ActiveRecord::Migration
  def self.up
    create_table :departments do |t|
      t.string   "name"
      t.boolean  "business_department"
    end
  end

  def self.down
    drop_table :departments
  end
end
