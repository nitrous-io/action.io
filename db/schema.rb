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

ActiveRecord::Schema.define(:version => 20130816083031) do

  create_table "addon_admins", :force => true do |t|
    t.integer  "user_id"
    t.integer  "addon_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "addon_admins", ["addon_id", "user_id"], :name => "index_addon_admins_on_addon_id_and_user_id", :unique => true
  add_index "addon_admins", ["addon_id"], :name => "index_addon_admins_on_addon_id"
  add_index "addon_admins", ["user_id"], :name => "index_addon_admins_on_user_id"

  create_table "addon_categories", :force => true do |t|
    t.string   "name",        :null => false
    t.string   "icon",        :null => false
    t.text     "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "addon_features", :force => true do |t|
    t.integer  "addon_id"
    t.string   "name",        :null => false
    t.string   "icon"
    t.text     "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "addon_plan_benefits", :force => true do |t|
    t.integer  "addon_plan_id"
    t.string   "name",          :null => false
    t.string   "value",         :null => false
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "addon_plans", :force => true do |t|
    t.integer  "addon_id"
    t.string   "name",       :null => false
    t.integer  "price"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "addon_subscriptions", :force => true do |t|
    t.integer  "box_id",                                            :null => false
    t.string   "state",                 :default => "unsubscribed", :null => false
    t.string   "resource_id"
    t.text     "encrypted_env_vars"
    t.string   "encrypted_env_vars_iv"
    t.datetime "created_at",                                        :null => false
    t.datetime "updated_at",                                        :null => false
    t.integer  "addon_plan_id"
  end

  add_index "addon_subscriptions", ["addon_plan_id"], :name => "index_addon_subscriptions_on_addon_plan_id"
  add_index "addon_subscriptions", ["box_id", "addon_plan_id"], :name => "index_addon_subscriptions_on_box_id_and_addon_plan_id"
  add_index "addon_subscriptions", ["box_id"], :name => "index_addon_subscriptions_on_box_id"

  create_table "addons", :force => true do |t|
    t.string   "uid",                                            :null => false
    t.text     "config_vars",                                    :null => false
    t.text     "required_vars"
    t.string   "production_base_url",                            :null => false
    t.string   "production_sso_url",                             :null => false
    t.string   "test_base_url",                                  :null => false
    t.string   "test_sso_url",                                   :null => false
    t.string   "encrypted_password",                             :null => false
    t.string   "encrypted_password_iv",                          :null => false
    t.string   "encrypted_sso_salt",                             :null => false
    t.string   "encrypted_sso_salt_iv",                          :null => false
    t.string   "state",                 :default => "submitted", :null => false
    t.text     "description"
    t.integer  "owner_id",                                       :null => false
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.integer  "addon_category_id"
    t.string   "name"
    t.string   "icon"
    t.string   "tagline"
  end

  add_index "addons", ["addon_category_id"], :name => "index_addons_on_addon_category_id"
  add_index "addons", ["uid"], :name => "index_addons_on_uid"

  create_table "authentications", :force => true do |t|
    t.integer  "user_id",                       :null => false
    t.string   "provider",                      :null => false
    t.string   "uid",                           :null => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.string   "token"
    t.string   "username"
    t.text     "meta"
    t.boolean  "confirmed",  :default => false, :null => false
    t.string   "secret"
  end

  add_index "authentications", ["provider", "uid"], :name => "index_authentications_on_provider_and_uid"
  add_index "authentications", ["user_id"], :name => "index_authentications_on_user_id"

  create_table "bonuses", :force => true do |t|
    t.integer  "user_id",         :null => false
    t.datetime "invite_friends"
    t.datetime "github"
    t.datetime "google"
    t.datetime "twitter"
    t.datetime "facebook"
    t.datetime "linkedin"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.datetime "accepted_invite"
    t.datetime "chrome_app"
    t.datetime "twitter_follow"
    t.datetime "tweet_sent"
  end

  add_index "bonuses", ["user_id"], :name => "index_bonuses_on_user_id"

  create_table "box_limit_hit_events", :force => true do |t|
    t.string   "kind"
    t.string   "logged_event_id"
    t.datetime "limit_hit_at"
    t.integer  "box_id"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "box_limit_hit_events", ["box_id"], :name => "index_box_limit_hit_events_on_box_id"
  add_index "box_limit_hit_events", ["logged_event_id"], :name => "index_box_limit_hit_events_on_logged_event_id"

  create_table "box_templates", :force => true do |t|
    t.string   "name",                           :null => false
    t.text     "description",                    :null => false
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.boolean  "enabled",     :default => false, :null => false
    t.string   "runtime"
    t.boolean  "admin",       :default => false, :null => false
  end

  create_table "box_users", :force => true do |t|
    t.integer  "box_id",     :null => false
    t.integer  "user_id",    :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "box_users", ["box_id", "user_id"], :name => "index_box_admins_on_box_id_and_user_id", :unique => true
  add_index "box_users", ["box_id"], :name => "index_box_admins_on_box_id"
  add_index "box_users", ["user_id"], :name => "index_box_admins_on_user_id"

  create_table "boxes", :force => true do |t|
    t.string   "name",                                         :null => false
    t.string   "host"
    t.string   "state",                    :default => "born", :null => false
    t.integer  "box_template_id"
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.integer  "owner_id"
    t.integer  "region_id"
    t.integer  "port"
    t.datetime "terminated_at"
    t.datetime "touched_at"
    t.string   "auth_username"
    t.string   "auth_password"
    t.integer  "memory",                   :default => 384,    :null => false
    t.integer  "storage",                  :default => 750,    :null => false
    t.integer  "latest_snapshot_id"
    t.boolean  "maintenance",              :default => false,  :null => false
    t.datetime "last_hit_memory_limit_at"
  end

  add_index "boxes", ["owner_id"], :name => "index_boxes_on_owner_id"

  create_table "collaboration_invites", :force => true do |t|
    t.string   "email",                                     :null => false
    t.string   "state",            :default => "activated", :null => false
    t.datetime "accepted_at"
    t.datetime "last_reminded_at"
    t.integer  "box_id"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
  end

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

  create_table "documents", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "box_id",     :null => false
    t.string   "pathname",   :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "documents", ["box_id", "user_id"], :name => "index_documents_on_box_id_and_user_id"

  create_table "invites", :force => true do |t|
    t.string   "email",                                     :null => false
    t.string   "state",            :default => "activated", :null => false
    t.integer  "inviting_user_id"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.string   "referral_code"
    t.datetime "last_reminded_at"
    t.datetime "accepted_at"
    t.integer  "box_id"
    t.integer  "invited_user_id"
  end

  add_index "invites", ["referral_code"], :name => "index_invites_on_referral_code"

  create_table "key_pairs", :force => true do |t|
    t.integer  "box_id",                   :null => false
    t.text     "public_key",               :null => false
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
    t.text     "encrypted_private_key",    :null => false
    t.string   "encrypted_private_key_iv", :null => false
  end

  add_index "key_pairs", ["box_id"], :name => "index_key_pairs_on_box_id"

  create_table "key_values", :force => true do |t|
    t.string   "key",        :null => false
    t.text     "json_value"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "key_values", ["key"], :name => "index_key_values_on_key", :unique => true

  create_table "mac_app_updates", :force => true do |t|
    t.string   "version",                      :null => false
    t.string   "title",                        :null => false
    t.text     "release_notes",                :null => false
    t.string   "url",                          :null => false
    t.integer  "file_size",     :default => 0, :null => false
    t.datetime "published_at"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
  end

  create_table "n2o_allocations", :force => true do |t|
    t.integer  "user_id",                       :null => false
    t.integer  "amount",         :default => 0, :null => false
    t.integer  "kind",                          :null => false
    t.string   "description"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "deallocated_at"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  add_index "n2o_allocations", ["deallocated_at"], :name => "index_n2o_allocations_on_deallocated_at"
  add_index "n2o_allocations", ["user_id", "deallocated_at"], :name => "index_n2o_allocations_on_user_id_and_deallocated_at"
  add_index "n2o_allocations", ["user_id"], :name => "index_n2o_allocations_on_user_id"

  create_table "n2o_fills", :force => true do |t|
    t.integer  "user_id",                      :null => false
    t.integer  "amount",        :default => 0, :null => false
    t.integer  "kind",                         :null => false
    t.string   "description"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.string   "resource_type"
    t.integer  "resource_id"
  end

  add_index "n2o_fills", ["user_id"], :name => "index_n2o_fills_on_user_id"

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

  create_table "plans", :force => true do |t|
    t.string   "name",        :null => false
    t.text     "description"
    t.boolean  "active"
    t.integer  "price_cents"
    t.integer  "num_boxes"
    t.integer  "ram"
    t.integer  "disk_space"
    t.boolean  "ssh_access"
    t.boolean  "sleepless"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.boolean  "demo"
  end

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
    t.string   "state",          :default => "up",  :null => false
  end

  add_index "regions", ["enabled"], :name => "index_regions_on_enabled"
  add_index "regions", ["name"], :name => "index_regions_on_name", :unique => true

  create_table "snapshots", :force => true do |t|
    t.string   "name",                           :null => false
    t.string   "description"
    t.string   "url"
    t.string   "state",       :default => "new", :null => false
    t.boolean  "public",      :default => false
    t.integer  "box_id"
    t.integer  "owner_id"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
  end

  create_table "subscriptions", :force => true do |t|
    t.integer  "plan_id"
    t.integer  "user_id"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "expires_at"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "user_profiles", :force => true do |t|
    t.integer  "user_id",                                               :null => false
    t.boolean  "subscribed_to_monthly_newsletter",    :default => true
    t.boolean  "subscribed_to_product_announcements", :default => true
    t.datetime "created_at",                                            :null => false
    t.datetime "updated_at",                                            :null => false
  end

  add_index "user_profiles", ["user_id"], :name => "index_user_profiles_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "encrypted_password"
    t.string   "email",                                              :null => false
    t.string   "full_name"
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                   :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
    t.string   "authentication_token"
    t.boolean  "admin",                           :default => false, :null => false
    t.integer  "rewardable_invites_count",        :default => 10,    :null => false
    t.integer  "max_n2o",                         :default => 0,     :null => false
    t.integer  "used_n2o",                        :default => 0,     :null => false
    t.string   "referral_code"
    t.integer  "accepted_invites",                :default => 0,     :null => false
    t.boolean  "intro_seen",                      :default => false, :null => false
    t.string   "unconfirmed_email"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.boolean  "in_private_beta",                 :default => false, :null => false
    t.integer  "referral_n2o"
    t.boolean  "addon_provider",                  :default => false
    t.boolean  "addon_provider_has_agreed_terms", :default => false
  end

  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["referral_code"], :name => "index_users_on_referral_code", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["username"], :name => "index_users_on_username", :unique => true

end
