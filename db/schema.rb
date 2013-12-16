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

ActiveRecord::Schema.define(:version => 20131213084423) do

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

  create_table "billing_profiles", :force => true do |t|
    t.integer  "user_id"
    t.string   "stripe_id"
    t.string   "last_four"
    t.string   "card_type"
    t.integer  "exp_month"
    t.integer  "exp_year"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "billing_profiles", ["exp_month", "exp_year"], :name => "index_billing_profiles_on_exp_month_and_exp_year"
  add_index "billing_profiles", ["stripe_id"], :name => "index_billing_profiles_on_stripe_id", :unique => true
  add_index "billing_profiles", ["user_id"], :name => "index_billing_profiles_on_user_id"

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
    t.datetime "business_survey"
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
    t.string   "name",                                          :null => false
    t.string   "host"
    t.string   "state",                     :default => "born", :null => false
    t.integer  "box_template_id"
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
    t.integer  "owner_id"
    t.integer  "region_id"
    t.integer  "port"
    t.datetime "terminated_at"
    t.datetime "touched_at"
    t.integer  "memory",                    :default => 384,    :null => false
    t.integer  "storage",                   :default => 750,    :null => false
    t.datetime "last_hit_memory_limit_at"
    t.string   "version"
    t.datetime "last_heartbeat_tracked_at"
    t.string   "auth_username"
    t.string   "auth_password"
    t.integer  "cpu_multiplier",            :default => 1
    t.integer  "virtual_memory"
    t.datetime "force_shutdown_at"
  end

  add_index "boxes", ["force_shutdown_at", "state"], :name => "index_boxes_on_force_shutdown_at_and_state"
  add_index "boxes", ["last_heartbeat_tracked_at", "state"], :name => "index_boxes_on_last_heartbeat_tracked_at_and_state"
  add_index "boxes", ["owner_id", "state"], :name => "index_boxes_on_owner_id_and_state"
  add_index "boxes", ["owner_id"], :name => "index_boxes_on_owner_id"
  add_index "boxes", ["state"], :name => "index_boxes_on_state"
  add_index "boxes", ["touched_at", "state"], :name => "index_boxes_on_touched_at_and_state"
  add_index "boxes", ["version"], :name => "index_boxes_on_version"

  create_table "collaboration_invites", :force => true do |t|
    t.string   "email",                                     :null => false
    t.string   "state",            :default => "activated", :null => false
    t.datetime "accepted_at"
    t.datetime "last_reminded_at"
    t.integer  "box_id"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
  end

  create_table "coupons", :force => true do |t|
    t.string   "code"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.boolean  "active"
    t.integer  "duration"
    t.integer  "percent_off"
  end

  add_index "coupons", ["code"], :name => "index_coupons_on_code", :unique => true

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
    t.string   "email",                                     :null => false
    t.string   "state",            :default => "activated", :null => false
    t.integer  "inviting_user_id"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.string   "referral_code"
    t.datetime "last_reminded_at"
    t.datetime "accepted_at"
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

  create_table "past_subscriptions", :force => true do |t|
    t.integer  "user_id",         :null => false
    t.string   "plan_name"
    t.string   "plan_stripe_id"
    t.float    "plan_price"
    t.string   "plan_interval"
    t.integer  "plan_n2o_amount"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "plans", :force => true do |t|
    t.string   "name"
    t.string   "stripe_id"
    t.float    "price"
    t.string   "interval"
    t.integer  "n2o_amount"
    t.text     "features"
    t.boolean  "highlight"
    t.integer  "display_order"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.integer  "cpu_multiplier",  :default => 1
    t.integer  "vmem_multiplier", :default => 1
  end

  add_index "plans", ["stripe_id"], :name => "index_subscription_plans_on_stripe_id", :unique => true

  create_table "public_keys", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.string   "name"
    t.text     "key",        :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "public_keys", ["user_id"], :name => "index_public_keys_on_user_id"

  create_table "receipts", :force => true do |t|
    t.datetime "period_start"
    t.datetime "period_end"
    t.text     "lines"
    t.integer  "subtotal"
    t.integer  "total"
    t.integer  "billing_profile_id", :null => false
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  add_index "receipts", ["billing_profile_id"], :name => "index_receipts_on_billing_profile_id"

  create_table "regions", :force => true do |t|
    t.string   "name",                              :null => false
    t.string   "description",                       :null => false
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.boolean  "enabled",        :default => false, :null => false
    t.string   "box_server_uri"
    t.string   "coach_uri"
    t.string   "state",          :default => "up",  :null => false
    t.string   "version"
  end

  add_index "regions", ["enabled"], :name => "index_regions_on_enabled"
  add_index "regions", ["name"], :name => "index_regions_on_name", :unique => true

  create_table "subscriptions", :force => true do |t|
    t.integer  "plan_id",                                   :null => false
    t.integer  "billing_profile_id"
    t.integer  "coupon_id"
    t.string   "state",              :default => "pending", :null => false
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.integer  "user_id"
    t.boolean  "payment_due",        :default => false
    t.integer  "pending_plan_id"
    t.string   "stripe_invoice_id"
  end

  add_index "subscriptions", ["billing_profile_id"], :name => "index_subscriptions_on_billing_profile_id"
  add_index "subscriptions", ["stripe_invoice_id"], :name => "index_subscriptions_on_stripe_invoice_id"

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
    t.string   "email",                                       :null => false
    t.string   "full_name"
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",            :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
    t.string   "authentication_token"
    t.boolean  "admin",                    :default => false, :null => false
    t.integer  "rewardable_invites_count", :default => 10,    :null => false
    t.integer  "max_n2o",                  :default => 0,     :null => false
    t.integer  "used_n2o",                 :default => 0,     :null => false
    t.string   "referral_code"
    t.integer  "accepted_invites",         :default => 0,     :null => false
    t.boolean  "intro_seen",               :default => false, :null => false
    t.string   "unconfirmed_email"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.boolean  "in_private_beta",          :default => false, :null => false
    t.integer  "referral_n2o"
    t.string   "stripe_customer_id"
    t.datetime "banned_at"
  end

  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["referral_code"], :name => "index_users_on_referral_code", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["stripe_customer_id"], :name => "index_users_on_stripe_customer_id"
  add_index "users", ["username"], :name => "index_users_on_username", :unique => true

end
