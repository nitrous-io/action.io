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

ActiveRecord::Schema.define(:version => 20130212080936) do

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

  create_table "box_templates", :force => true do |t|
    t.string   "name",                           :null => false
    t.text     "description",                    :null => false
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.boolean  "enabled",     :default => false, :null => false
    t.string   "runtime"
    t.boolean  "admin",       :default => false, :null => false
  end

  create_table "boxes", :force => true do |t|
    t.string   "name",                                :null => false
    t.string   "host"
    t.string   "state",           :default => "born", :null => false
    t.integer  "box_template_id"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.integer  "owner_id"
    t.integer  "region_id"
    t.integer  "port"
    t.datetime "terminated_at"
  end

  add_index "boxes", ["name", "owner_id"], :name => "index_boxes_on_name_and_owner_id", :unique => true
  add_index "boxes", ["owner_id"], :name => "index_boxes_on_owner_id"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "invites", :force => true do |t|
    t.string   "email",                                   :null => false
    t.string   "invite_code"
    t.string   "state",            :default => "pending", :null => false
    t.integer  "inviting_user_id"
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
    t.string   "ip"
    t.string   "city"
    t.string   "country"
    t.string   "country_code"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "referral_code"
    t.string   "referrer_code"
    t.integer  "referred_visits",  :default => 0,         :null => false
  end

  add_index "invites", ["referral_code"], :name => "index_invites_on_referral_code"
  add_index "invites", ["referrer_code"], :name => "index_invites_on_referrer_code"

  create_table "key_pairs", :force => true do |t|
    t.integer  "box_id",                   :null => false
    t.text     "public_key",               :null => false
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
    t.text     "encrypted_private_key",    :null => false
    t.string   "encrypted_private_key_iv", :null => false
  end

  add_index "key_pairs", ["box_id"], :name => "index_key_pairs_on_box_id"

  create_table "oauth_access_grants", :force => true do |t|
    t.integer  "resource_owner_id", :null => false
    t.integer  "application_id",    :null => false
    t.string   "token",             :null => false
    t.integer  "expires_in",        :null => false
    t.string   "redirect_uri",      :null => false
    t.datetime "created_at",        :null => false
    t.datetime "revoked_at"
    t.string   "scopes"
  end

  add_index "oauth_access_grants", ["token"], :name => "index_oauth_access_grants_on_token", :unique => true

  create_table "oauth_access_tokens", :force => true do |t|
    t.integer  "resource_owner_id"
    t.integer  "application_id",    :null => false
    t.string   "token",             :null => false
    t.string   "refresh_token"
    t.integer  "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at",        :null => false
    t.string   "scopes"
  end

  add_index "oauth_access_tokens", ["refresh_token"], :name => "index_oauth_access_tokens_on_refresh_token", :unique => true
  add_index "oauth_access_tokens", ["resource_owner_id"], :name => "index_oauth_access_tokens_on_resource_owner_id"
  add_index "oauth_access_tokens", ["token"], :name => "index_oauth_access_tokens_on_token", :unique => true

  create_table "oauth_applications", :force => true do |t|
    t.string   "name",         :null => false
    t.string   "uid",          :null => false
    t.string   "secret",       :null => false
    t.string   "redirect_uri", :null => false
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.integer  "owner_id"
    t.string   "owner_type"
  end

  add_index "oauth_applications", ["owner_id", "owner_type"], :name => "index_oauth_applications_on_owner_id_and_owner_type"
  add_index "oauth_applications", ["uid"], :name => "index_oauth_applications_on_uid", :unique => true

  create_table "public_keys", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.string   "name"
    t.text     "key",        :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "public_keys", ["user_id"], :name => "index_public_keys_on_user_id"

  create_table "regions", :force => true do |t|
    t.string   "name",                              :null => false
    t.string   "description",                       :null => false
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.boolean  "enabled",        :default => false, :null => false
    t.string   "box_server_uri"
    t.string   "coach_uri"
  end

  add_index "regions", ["enabled"], :name => "index_regions_on_enabled"
  add_index "regions", ["name"], :name => "index_regions_on_name", :unique => true

  create_table "snapshots", :force => true do |t|
    t.string   "name",        :null => false
    t.string   "description"
    t.boolean  "public"
    t.integer  "box_id"
    t.integer  "owner_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "username",                                  :null => false
    t.string   "encrypted_password"
    t.string   "email",                                     :null => false
    t.string   "full_name"
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.string   "authentication_token"
    t.string   "invite_code"
    t.boolean  "admin",                  :default => false, :null => false
    t.integer  "available_invites",      :default => 0,     :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["username"], :name => "index_users_on_username", :unique => true

end
