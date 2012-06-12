ActiveModel::Serializer.root false

module ActionController::Serialization
  def _render_option_json_with_root_false(json, options)
    _render_option_json_without_root_false(json, options.merge(root: false))
  end
  alias_method_chain :_render_option_json, :root_false
end

class ActiveRecord::Base
  def serialize_as_hash
    active_model_serializer.new(self).as_json
  end

  def serialize_as_json
    active_model_serializer.new(self).to_json
  end
end

class Array
  def serialize_as_hash
    active_model_serializer.new(self).as_json
  end

  def serialize_as_json
    active_model_serializer.new(self).to_json
  end
end

