module EmberJS
  def self.route(path, query_params={})
    if query_params.present?
      "#{path}?#{query_params.to_query}"
    else
      path
    end
  end
end
