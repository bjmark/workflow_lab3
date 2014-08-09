# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140809032439) do

  create_table "cash_positions", :force => true do |t|
    t.string   "name"
    t.integer  "project_id"
    t.integer  "workflow_status_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "departments", :force => true do |t|
    t.string  "name"
    t.boolean "business_department"
  end

  create_table "departments_users", :id => false, :force => true do |t|
    t.integer "department_id"
    t.integer "user_id"
  end

  create_table "disbursement_applications", :force => true do |t|
    t.string   "name"
    t.integer  "workflow_status_id"
    t.integer  "cash_position_id"
    t.text     "hhash"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "process_journals", :force => true do |t|
    t.integer  "workflow_id"
    t.integer  "user_id"
    t.integer  "as_role_id"
    t.text     "comments"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.boolean  "ok"
    t.string   "wfid"
    t.text     "original_tree"
    t.text     "current_tree"
    t.string   "workflow_action"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "projects", :force => true do |t|
    t.string   "name"
    t.integer  "handler_id"
    t.integer  "cohandler_id"
    t.integer  "workflow_status_id"
    t.text     "hhash"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string  "name"
    t.string  "code"
    t.boolean "department_head", :default => false
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  create_table "user_workflow_results", :force => true do |t|
    t.integer  "user_id"
    t.integer  "workflow_result_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string  "name"
    t.boolean "admin"
  end

  create_table "workflow_results", :force => true do |t|
    t.string   "workflow_name"
    t.string   "wfid"
    t.string   "target"
    t.string   "result"
    t.integer  "final_user_id"
    t.string   "project"
    t.datetime "process_at"
    t.string   "target_type"
    t.integer  "target_id"
    t.string   "ok",            :limit => 1
    t.string   "finish",        :limit => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "workflow_statuses", :force => true do |t|
    t.string "name"
    t.string "code"
  end

  create_table "workflows", :force => true do |t|
    t.text     "definition", :null => false
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
