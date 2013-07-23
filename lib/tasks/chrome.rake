# This is the rake task for building chrome packaged app
#
# It should consider the environment variables
#
# and spit out the following files to a directory:
#   - manifest.json (parsed)
#   - icons
#   - rendered web app index
#   - precompiled assets
#
# then it should create a zip file of the output directory
#
# TODO: move the generated stuff out of public to tmp

namespace :chrome do
  desc "builds the chrome package app"
  task :build => :environment do
    build_path = "#{Rails.root}/tmp"
    output_directory = "/chrome-app"
    container_uri = '/app/chrome'
    container_file_path = "#{output_directory}/pages/main.html"

    puts "creating the container page"
    app = ActionDispatch::Integration::Session.new(Rails.application)
    app.https!
    app.get container_uri
    ApplicationController.page_cache_directory = build_path
    ApplicationController.cache_page(app.response.body, container_file_path)
    puts "saved container in #{container_file_path}"

    puts "bundling the assets"
    Rails.application.config.assets.prefix = "#{output_directory}/assets"
    old_public_path = Rails.application.paths["public"]
    Rails.application.paths["public"] = [build_path]

    Rake::Task["assets:precompile"].invoke

    Rails.application.paths["public"] = old_public_path
    puts "bundled the assets"

    puts "copying the manifest and icons"
    system "cp -R dev/chrome_template/* #{build_path}#{output_directory}"
    puts "copied the manifest and icons"
  end
end
