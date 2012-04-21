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

ActiveRecord::Schema.define(:version => 20120421102842) do

  create_table "authentications", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.string   "provider",   :null => false
    t.string   "uid",        :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "token"
  end

  add_index "authentications", ["provider", "uid"], :name => "index_authentications_on_provider_and_uid"
  add_index "authentications", ["user_id"], :name => "index_authentications_on_user_id"

  create_table "box_admins", :force => true do |t|
    t.integer  "box_id",     :null => false
    t.integer  "user_id",    :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "box_admins", ["box_id", "user_id"], :name => "index_box_admins_on_box_id_and_user_id", :unique => true
  add_index "box_admins", ["box_id"], :name => "index_box_admins_on_box_id"
  add_index "box_admins", ["user_id"], :name => "index_box_admins_on_user_id"

  create_table "box_hosts", :force => true do |t|
    t.integer  "region_id",  :null => false
    t.string   "name",       :null => false
    t.string   "host",       :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "box_hosts", ["region_id"], :name => "index_box_hosts_on_region_id"

  create_table "box_templates", :force => true do |t|
    t.string   "name",        :null => false
    t.string   "image",       :null => false
    t.text     "description", :null => false
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "boxes", :force => true do |t|
    t.string   "name",                                        :null => false
    t.string   "host"
    t.string   "state",           :default => "provisioning", :null => false
    t.integer  "box_template_id"
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
    t.integer  "owner_id"
    t.integer  "region_id"
    t.integer  "tty_port"
    t.string   "key",                                         :null => false
    t.integer  "port"
  end

  add_index "boxes", ["name"], :name => "index_boxes_on_name", :unique => true
  add_index "boxes", ["owner_id"], :name => "index_boxes_on_owner_id"

  create_table "public_keys", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.string   "name"
    t.text     "key",        :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "public_keys", ["user_id"], :name => "index_public_keys_on_user_id"

  create_table "regions", :force => true do |t|
    t.string   "name",        :null => false
    t.string   "description", :null => false
    t.string   "ami",         :null => false
    t.text     "keypair",     :null => false
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "regions", ["name"], :name => "index_regions_on_name", :unique => true

  create_table "users", :force => true do |t|
    t.string   "username",                              :null => false
    t.string   "encrypted_password"
    t.string   "email",                                 :null => false
    t.string   "full_name",                             :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.string   "authentication_token"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["username"], :name => "index_users_on_username", :unique => true

end
