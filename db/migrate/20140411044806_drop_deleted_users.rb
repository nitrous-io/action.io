class DropDeletedUsers < ActiveRecord::Migration
  def up
    rows = ActiveRecord::Base::connection.execute("SELECT id FROM users WHERE id IN (SELECT user_id FROM deleted_users)")
    if rows.count != 0
      raise "User IDs already exist for #{rows.count} deleted users: #{rows.map {|row| row['id'] }.join(', ') }"
    end

    # reuse deleted_at for user updated_at
    # encrypted_password will be nil, which always fails authentication
    execute <<-SQL
      INSERT INTO users (id, email, username, created_at, updated_at, deleted_at)
        SELECT      user_id, email, username, created_at, deleted_at, deleted_at FROM deleted_users
    SQL

    drop_table :deleted_users
  end

  def down
    # technically can be done but deemed not worth the time
    raise ActiveRecord::IrreversibleMigration
  end
end
