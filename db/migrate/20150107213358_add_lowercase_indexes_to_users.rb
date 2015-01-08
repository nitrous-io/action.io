class AddLowercaseIndexesToUsers < ActiveRecord::Migration
  def up
    # note that schema.rb will not capture indexes with expressions correctly
    execute "CREATE INDEX index_users_on_lower_email_and_deleted_at ON users (lower(email), deleted_at);"
    execute "CREATE INDEX index_users_on_lower_username_and_deleted_at ON users (lower(username), deleted_at);"
  end

  def down
    execute "DROP INDEX index_users_on_lower_email_and_deleted_at"
    execute "DROP INDEX index_users_on_lower_username_and_deleted_at"
  end
end
