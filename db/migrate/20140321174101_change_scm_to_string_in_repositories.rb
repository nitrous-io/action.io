class ChangeScmToStringInRepositories < ActiveRecord::Migration
  def up
    change_column :repositories, :scm, :string, default: 'unsupported'
    execute "UPDATE repositories SET scm='unsupported' WHERE scm='0'"
    execute "UPDATE repositories SET scm='git' WHERE scm='1'"
    execute "UPDATE repositories SET scm='mercurial' WHERE scm='2'"
  end

  def down
    execute "UPDATE repositories SET scm='0' WHERE scm='unsupported'"
    execute "UPDATE repositories SET scm='1' WHERE scm='git'"
    execute "UPDATE repositories SET scm='2' WHERE scm='mercurial'"
    execute <<-SQL
      ALTER TABLE "repositories"
        ALTER COLUMN "scm" DROP DEFAULT,
        ALTER COLUMN "scm" TYPE integer USING CAST("scm" AS INTEGER),
        ALTER COLUMN "scm" SET DEFAULT 0
    SQL
  end
end
