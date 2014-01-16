class DeletedUser < ActiveRecord::Base
  attr_accessible :user_id, :email, :username, :created_at, :deleted_at
end
