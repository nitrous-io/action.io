module EmberJS
  EMBER_APP_PATH = '/app'.freeze

  def self.route(path, query_params={})
    ember_path = path
    if query_params.present?
      ember_path = [path, query_params.to_query].join('?')
    end

    [EMBER_APP_PATH, ember_path].join('#/')
  end
end
