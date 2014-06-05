namespace :one_off do
  task :populate_free_boxhosts => :environment do
    # TODO after this has been run live, can remove 'host' column from boxes

    hosts = Box.select('host').distinct.where('host IS NOT NULL').pluck(:host)
    ActiveRecord::Base.transaction do
      hosts.each do |host|
        name = host.gsub(/\.nitrousbox.com$/, '')
        if name =~ /\d+\.\d+\.\d+\.\d+/ # very loose regex, for dev only so accuracy not as important
          name = "local-#{name}".gsub('.', '-')
        end
        new_host = FreeBoxhost.new(name: name)
        new_host.state = 'running'
        # TODO any other information we want to populate here?
        new_host.save!
        Box.where(host: host).update_all(boxhost_id: new_host.id)
      end
    end
  end
end
