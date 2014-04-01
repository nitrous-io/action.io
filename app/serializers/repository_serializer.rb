class RepositorySerializer < ActiveModel::Serializer
  attributes :id,
    :box_id,
    :name,
    :full_name,
    :clone_url,
    :state,
    :failure_reason,
    :private,
    :cloned_at,
    :created_at,
    :scm
end
