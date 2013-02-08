module ActionUserAgentParser
  def self.parse(user_agent)
    matcher = user_agent.match(/^(\w+)\/([\d\.]+)\s+\(([^;]+);\s+([^;]+);\s+([^;]+)\)\s+([^\s]+)/)
    source = {}

    if matcher.present?
      source[:client] = matcher[1]
      source[:version] = matcher[2]
      source[:os_name] = matcher[3]
      source[:os_version_long] = matcher[4]
      source[:os_version] = matcher[4].split(' ')[0]
      source[:locale] = matcher[5]
      source[:git] = matcher[6]
    end

    source
  end
end
