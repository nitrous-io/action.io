class Repository < ::Hashie::Dash
  property :id
  property :name
  property :full_name
  property :private
  property :html_url
  property :clone_url
  property :git_url
  property :ssh_url
end
