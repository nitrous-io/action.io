class PublicKeySerializer < ActiveModel::Serializer
  attributes :id, :user_id, :name, :md5_fingerprint
end
