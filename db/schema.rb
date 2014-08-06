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

ActiveRecord::Schema.define(:version => 20140805060831) do

  create_table "departments", :force => true do |t|
    t.string  "name"
    t.boolean "business_department"
  end

  create_table "departments_users", :id => false, :force => true do |t|
    t.integer "department_id"
    t.integer "user_id"
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

  create_table "users", :force => true do |t|
    t.string  "name"
    t.boolean "admin"
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
