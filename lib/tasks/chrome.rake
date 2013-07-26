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
  desc "bundles assets"
  task :build => :environment do
    build_path = "#{Rails.root}/tmp"
    compiled_dir = "#{build_path}/chrome_app"
    filename = 'nitrous-chrome-app'
    container_uri = '/app/chrome'

    puts "bundling assets"
    Rake::Task["assets:precompile"].invoke
    puts "bundled the assets"

    puts "creating the container page"
    app = ActionDispatch::Integration::Session.new(Rails.application)
    app.https!
    app.get "/app/chrome"
    ApplicationController.cache_page(app.response.body, "/chrome.html")
    puts "created the container page"

    puts "gather files and building package"
    system "cp -R dev/chrome_app_template/* #{compiled_dir}"
    system "mv public/assets #{compiled_dir}/assets"
    system "mv public/chrome.html #{compiled_dir}/index.html"
    system "cd #{compiled_dir}; zip -r ../'#{filename}'.zip *"
    puts "build complete!"
  end
end
