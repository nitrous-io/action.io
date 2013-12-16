namespace :stripe do
  task 'plans:prepare' => 'environment' do
    begin
      Plan.order(:stripe_id).each do |plan|
        Stripe::Plan.create(
          :amount => plan.price_in_cents,
          :interval => plan.interval,
          :name => plan.name,
          :currency => 'usd',
          :id => plan.stripe_id
        )
        puts "Added plan '#{plan.name}' to Stripe."
      end
    rescue => e
      puts e
    end
  end
end
