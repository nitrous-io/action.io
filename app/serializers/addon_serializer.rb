class AddonSerializer < ActiveModel::Serializer
  attributes :id, :uid, :name, :tagline
  has_one :addon_category
end

