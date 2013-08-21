namespace :stripe do
  task 'plans:prepare' => 'environment' do
    begin
      SubscriptionPlan.order(:stripe_id).each do |plan|
        Stripe::Plan.create(
          :amount => plan.price.to_i * 100,
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
