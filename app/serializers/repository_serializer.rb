class RepositorySerializer < ActiveModel::Serializer
  attributes :id,
    :box_id,
    :name,
    :full_name,
    :clone_url,
    :state,
    :private,
    :cloned_at,
    :created_at
end
